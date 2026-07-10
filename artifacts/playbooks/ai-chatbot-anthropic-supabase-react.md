# UNIVERSAL PRINCIPLES APPLY — read first:
# ~/.hermes/playbooks/universal-principles.md

# STACK PLAYBOOK: AI Chatbot / Embedded Assistant
# Anthropic API + Supabase Edge Functions + React
# Version: 1.0
# Reference: Amara chatbot (Foremost Capital, May 2026)
# Michael reads this before generating task CODE sections
# for any project requiring an embedded AI assistant.

---

## STACK IDENTITY

```
AI provider:    Anthropic Claude API (primary)
Model:          claude-haiku-4-5-20251001 (fast, cheap, for chat)
                claude-sonnet-4-20250514 (complex reasoning, if needed)
Backend:        Supabase Edge Functions (Deno runtime)
Database:       Supabase (conversation history, rate limiting)
Frontend:       React + Tailwind (embedded widget)
Streaming:      Server-Sent Events (SSE) for real-time responses
Auth:           Supabase Auth or anonymous session token
Rate limiting:  Per-user, per-day limits (in Edge Function)
```

---

## KNOWN PITFALLS — READ BEFORE GENERATING ANY TASK

1. **ANTHROPIC_API_KEY must never reach the browser.**
   Always call the Anthropic API from Supabase Edge Function.
   Never from React client code.
   The Edge Function is the only place that holds the key.
   Store in Supabase Vault or Edge Function secrets.

2. **Use streaming for chat — blocking responses feel broken.**
   Anthropic's API supports streaming via SSE.
   Supabase Edge Functions support streaming responses.
   Always stream — never wait for full response before rendering.
   Users expect to see words appearing as they are generated.

3. **Context window management is the main technical challenge.**
   Claude Haiku has 200k context window.
   But sending the full conversation history every turn gets expensive.
   Implement a sliding window: keep last N messages.
   Or summarise older messages before they drop off.
   For most client chatbots: last 10 messages is sufficient.

4. **System prompt is per-client, not hardcoded.**
   Store the system prompt in Supabase (or project_brand).
   The Edge Function reads it at runtime.
   This allows updating the chatbot's personality without redeploying.

5. **Rate limiting is mandatory.**
   Without rate limiting, one user can run up thousands of dollars.
   Implement per-user per-day message limits in Supabase.
   Reasonable defaults: 50 messages/day/user, 500 tokens/message.

6. **Conversation history must be stored.**
   Store in Supabase `conversations` and `messages` tables.
   This enables: session persistence, admin review, rate limiting, analytics.
   Never store raw API keys in conversation records.

7. **Haiku for speed, Sonnet only if needed.**
   claude-haiku is fast (< 1s first token) and cheap ($0.25/1M input).
   claude-sonnet is slower and 12x more expensive.
   For a customer-facing chatbot on a client website: always Haiku.
   Only upgrade to Sonnet if the task requires complex reasoning.

8. **Content moderation for client-facing chatbots.**
   Anthropic's API has built-in safety.
   But add explicit system prompt instructions about what the
   chatbot should and should not discuss.
   Log all conversations for client review.

---

## SUPABASE EDGE FUNCTION SETUP

```bash
# Install Supabase CLI (if not already done)
brew install supabase/tap/supabase

# Initialise in project
supabase init

# Create Edge Function
supabase functions new chat

# This creates: supabase/functions/chat/index.ts

# Set Edge Function secrets (these become env vars in the function)
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...

# Deploy Edge Function
supabase functions deploy chat

# Test locally
supabase functions serve chat --env-file .env.local
```

---

## SUPABASE SCHEMA

```sql
-- Conversations (one per chat session)
CREATE TABLE conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_token text NOT NULL,   -- anonymous user identifier
  user_id uuid REFERENCES auth.users(id),  -- if authenticated
  client_id uuid REFERENCES clients(id),   -- which client's chatbot
  started_at timestamptz DEFAULT now(),
  last_message_at timestamptz DEFAULT now(),
  message_count integer DEFAULT 0,
  metadata jsonb DEFAULT '{}'
);

-- Messages (one per turn)
CREATE TABLE messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE,
  role text CHECK (role IN ('user', 'assistant')),
  content text NOT NULL,
  tokens_used integer,
  model text,
  created_at timestamptz DEFAULT now()
);

-- Rate limiting
CREATE TABLE chat_rate_limits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_token text NOT NULL,
  date date NOT NULL DEFAULT CURRENT_DATE,
  message_count integer DEFAULT 0,
  UNIQUE (session_token, date)
);

-- System prompts per client
CREATE TABLE chat_system_prompts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES clients(id),
  prompt text NOT NULL,
  chatbot_name text DEFAULT 'Assistant',
  model text DEFAULT 'claude-haiku-4-5-20251001',
  max_messages_per_day integer DEFAULT 50,
  is_active boolean DEFAULT true,
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX ON messages(conversation_id);
CREATE INDEX ON chat_rate_limits(session_token, date);
CREATE INDEX ON conversations(session_token);

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rate_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_system_prompts ENABLE ROW LEVEL SECURITY;

-- Public can insert/read own conversations via session token
CREATE POLICY "Session access" ON conversations
  FOR ALL USING (session_token = current_setting('request.jwt.claims', true)::json->>'session_token');

-- Service role reads all
CREATE POLICY "Service reads all" ON conversations
  FOR SELECT USING (auth.role() = 'service_role');
```

---

## SUPABASE EDGE FUNCTION

**supabase/functions/chat/index.ts**
```typescript
import Anthropic from 'npm:@anthropic-ai/sdk'
import { createClient } from 'npm:@supabase/supabase-js@2'

const anthropic = new Anthropic({
  apiKey: Deno.env.get('ANTHROPIC_API_KEY')!
})

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

interface ChatRequest {
  message: string
  conversationId?: string
  sessionToken: string
  clientId: string
}

Deno.serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': Deno.env.get('ALLOWED_ORIGIN') ?? '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { message, conversationId, sessionToken, clientId }: ChatRequest =
      await req.json()

    // 1. Rate limiting check
    const rateLimitOk = await checkRateLimit(sessionToken, clientId)
    if (!rateLimitOk) {
      return new Response(
        JSON.stringify({ error: 'Daily message limit reached. Please try again tomorrow.' }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 2. Get or create conversation
    const convId = conversationId ?? await createConversation(sessionToken, clientId)

    // 3. Get system prompt for this client
    const { data: promptData } = await supabase
      .from('chat_system_prompts')
      .select('prompt, chatbot_name, model')
      .eq('client_id', clientId)
      .eq('is_active', true)
      .single()

    const systemPrompt = promptData?.prompt ?? 'You are a helpful assistant.'
    const model = promptData?.model ?? 'claude-haiku-4-5-20251001'

    // 4. Get conversation history (last 10 messages)
    const { data: history } = await supabase
      .from('messages')
      .select('role, content')
      .eq('conversation_id', convId)
      .order('created_at', { ascending: false })
      .limit(10)

    const messages = [
      ...(history?.reverse() ?? []),
      { role: 'user' as const, content: message }
    ]

    // 5. Store user message
    await supabase.from('messages').insert({
      conversation_id: convId,
      role: 'user',
      content: message,
      model
    })

    // 6. Stream response from Anthropic
    const stream = await anthropic.messages.stream({
      model,
      max_tokens: 1024,
      system: systemPrompt,
      messages
    })

    let fullResponse = ''
    let inputTokens = 0
    let outputTokens = 0

    const encoder = new TextEncoder()
    const readable = new ReadableStream({
      async start(controller) {
        try {
          for await (const chunk of stream) {
            if (
              chunk.type === 'content_block_delta' &&
              chunk.delta.type === 'text_delta'
            ) {
              const text = chunk.delta.text
              fullResponse += text
              // Send as SSE
              controller.enqueue(
                encoder.encode(`data: ${JSON.stringify({ text })}\n\n`)
              )
            }
            if (chunk.type === 'message_delta') {
              outputTokens = chunk.usage.output_tokens
            }
            if (chunk.type === 'message_start') {
              inputTokens = chunk.message.usage.input_tokens
            }
          }

          // Save assistant response
          await supabase.from('messages').insert({
            conversation_id: convId,
            role: 'assistant',
            content: fullResponse,
            tokens_used: inputTokens + outputTokens,
            model
          })

          // Update rate limit counter
          await incrementRateLimit(sessionToken)

          // Update conversation
          await supabase
            .from('conversations')
            .update({
              last_message_at: new Date().toISOString(),
              message_count: messages.length + 1
            })
            .eq('id', convId)

          // Send done signal
          controller.enqueue(
            encoder.encode(`data: ${JSON.stringify({ done: true, conversationId: convId })}\n\n`)
          )
          controller.close()
        } catch (err) {
          controller.error(err)
        }
      }
    })

    return new Response(readable, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      }
    })
  } catch (err) {
    console.error('Chat function error:', err)
    return new Response(
      JSON.stringify({ error: 'Internal error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

async function checkRateLimit(sessionToken: string, clientId: string): Promise<boolean> {
  const { data: promptData } = await supabase
    .from('chat_system_prompts')
    .select('max_messages_per_day')
    .eq('client_id', clientId)
    .single()
  const limit = promptData?.max_messages_per_day ?? 50

  const { data } = await supabase
    .from('chat_rate_limits')
    .select('message_count')
    .eq('session_token', sessionToken)
    .eq('date', new Date().toISOString().split('T')[0])
    .single()

  return (data?.message_count ?? 0) < limit
}

async function incrementRateLimit(sessionToken: string): Promise<void> {
  const today = new Date().toISOString().split('T')[0]
  await supabase.rpc('increment_chat_rate_limit', {
    p_session_token: sessionToken,
    p_date: today
  })
}

async function createConversation(
  sessionToken: string,
  clientId: string
): Promise<string> {
  const { data } = await supabase
    .from('conversations')
    .insert({ session_token: sessionToken, client_id: clientId })
    .select('id')
    .single()
  return data!.id
}
```

**SQL function for rate limit increment:**
```sql
CREATE OR REPLACE FUNCTION increment_chat_rate_limit(
  p_session_token text,
  p_date date
) RETURNS void AS $$
BEGIN
  INSERT INTO chat_rate_limits (session_token, date, message_count)
  VALUES (p_session_token, p_date, 1)
  ON CONFLICT (session_token, date)
  DO UPDATE SET message_count = chat_rate_limits.message_count + 1;
END;
$$ LANGUAGE plpgsql;
```

---

## REACT CHAT WIDGET

**src/components/ChatWidget.tsx**
```tsx
import { useState, useRef, useEffect } from 'react'
import { supabase } from '../lib/supabase'

interface Message {
  role: 'user' | 'assistant'
  content: string
}

interface ChatWidgetProps {
  clientId: string
  botName?: string
  placeholder?: string
  primaryColor?: string
}

export function ChatWidget({
  clientId,
  botName = 'Assistant',
  placeholder = 'Ask me anything...',
  primaryColor = '#c0392b'
}: ChatWidgetProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [messages, setMessages] = useState<Message[]>([])
  const [input, setInput] = useState('')
  const [isStreaming, setIsStreaming] = useState(false)
  const [conversationId, setConversationId] = useState<string>()
  const [sessionToken] = useState(() => crypto.randomUUID())
  const messagesEndRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const sendMessage = async () => {
    if (!input.trim() || isStreaming) return
    const userMessage = input.trim()
    setInput('')
    setMessages(prev => [...prev, { role: 'user', content: userMessage }])
    setIsStreaming(true)

    // Add empty assistant message for streaming
    setMessages(prev => [...prev, { role: 'assistant', content: '' }])

    try {
      const { data: { session } } = await supabase.auth.getSession()
      const token = session?.access_token ?? ''

      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/chat`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`,
          },
          body: JSON.stringify({
            message: userMessage,
            conversationId,
            sessionToken,
            clientId
          })
        }
      )

      if (!response.ok) {
        const err = await response.json()
        throw new Error(err.error ?? 'Request failed')
      }

      const reader = response.body!.getReader()
      const decoder = new TextDecoder()

      while (true) {
        const { done, value } = await reader.read()
        if (done) break

        const chunk = decoder.decode(value)
        const lines = chunk.split('\n')

        for (const line of lines) {
          if (!line.startsWith('data: ')) continue
          const data = JSON.parse(line.slice(6))

          if (data.text) {
            setMessages(prev => {
              const updated = [...prev]
              updated[updated.length - 1] = {
                role: 'assistant',
                content: updated[updated.length - 1].content + data.text
              }
              return updated
            })
          }

          if (data.done && data.conversationId) {
            setConversationId(data.conversationId)
          }
        }
      }
    } catch (err) {
      setMessages(prev => {
        const updated = [...prev]
        updated[updated.length - 1] = {
          role: 'assistant',
          content: 'Sorry, something went wrong. Please try again.'
        }
        return updated
      })
    } finally {
      setIsStreaming(false)
    }
  }

  return (
    <>
      {/* Toggle button */}
      <button
        onClick={() => setIsOpen(prev => !prev)}
        style={{ backgroundColor: primaryColor }}
        className="fixed bottom-6 right-6 w-14 h-14 rounded-full text-white shadow-lg z-50 flex items-center justify-center text-2xl"
      >
        {isOpen ? '×' : '💬'}
      </button>

      {/* Chat window */}
      {isOpen && (
        <div className="fixed bottom-24 right-6 w-80 h-96 bg-[#111] border border-[#222] rounded-xl shadow-xl z-50 flex flex-col overflow-hidden">
          {/* Header */}
          <div style={{ backgroundColor: primaryColor }} className="p-4">
            <p className="text-white text-sm font-medium">{botName}</p>
          </div>

          {/* Messages */}
          <div className="flex-1 overflow-y-auto p-4 space-y-3">
            {messages.length === 0 && (
              <p className="text-[#555] text-xs text-center">
                How can I help you today?
              </p>
            )}
            {messages.map((msg, i) => (
              <div
                key={i}
                className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
              >
                <div
                  className={`max-w-[80%] rounded-lg px-3 py-2 text-xs ${
                    msg.role === 'user'
                      ? 'bg-[#1a1a1a] text-white'
                      : 'text-[#888]'
                  }`}
                >
                  {msg.content}
                  {msg.role === 'assistant' && isStreaming && i === messages.length - 1 && (
                    <span className="animate-pulse">▌</span>
                  )}
                </div>
              </div>
            ))}
            <div ref={messagesEndRef} />
          </div>

          {/* Input */}
          <div className="p-3 border-t border-[#222] flex gap-2">
            <input
              value={input}
              onChange={e => setInput(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && !e.shiftKey && sendMessage()}
              placeholder={placeholder}
              disabled={isStreaming}
              className="flex-1 bg-[#1a1a1a] text-xs text-white rounded px-3 py-2 outline-none placeholder:text-[#333] disabled:opacity-50"
            />
            <button
              onClick={sendMessage}
              disabled={isStreaming || !input.trim()}
              style={{ backgroundColor: primaryColor }}
              className="text-white text-xs px-3 py-2 rounded disabled:opacity-50"
            >
              →
            </button>
          </div>
        </div>
      )}
    </>
  )
}
```

**Usage in any page:**
```tsx
import { ChatWidget } from '../components/ChatWidget'

// In any page or layout:
<ChatWidget
  clientId="[client-uuid-from-supabase]"
  botName="Amara"
  placeholder="Ask Amara anything about our services..."
  primaryColor="#c0392b"
/>
```

---

## SYSTEM PROMPT TEMPLATE

```
You are [Bot Name], the AI assistant for [Company Name].

ABOUT THE COMPANY:
[2-3 sentences about who the company is and what they do]

YOUR ROLE:
- Answer questions about [Company Name]'s services and products
- Help visitors understand how [Company Name] can help them
- Guide interested visitors toward [primary CTA]

WHAT YOU CAN HELP WITH:
[List specific topics]

WHAT YOU CANNOT DO:
- Make specific pricing commitments (direct to contact form)
- Share confidential client information
- Speak on behalf of specific team members
- Discuss competitor companies

TONE:
[Professional / friendly / formal — match brand voice]

ESCALATION:
If a visitor wants to speak to a human or has a complex enquiry,
direct them to: [contact method] or [contact form URL]

Keep responses concise — 2-3 sentences unless more detail is needed.
Always be helpful and positive.
```

---

## TESTING PATTERNS

### Unit test — rate limit logic
```typescript
import { describe, it, expect } from 'vitest'

describe('chat rate limiting', () => {
  it('allows messages under limit', () => {
    const count = 40
    const limit = 50
    expect(count < limit).toBe(true)
  })

  it('blocks messages at limit', () => {
    const count = 50
    const limit = 50
    expect(count < limit).toBe(false)
  })
})
```

### Manual integration test
```bash
# Test Edge Function locally
supabase functions serve chat

# Send test message
curl -X POST http://localhost:54321/functions/v1/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer [anon-key]" \
  -d '{
    "message": "Hello",
    "sessionToken": "test-session-123",
    "clientId": "[client-uuid]"
  }'

# Expected: streaming SSE response with text chunks
```

---

## STANDARD DIRECTORY STRUCTURE

```
src/
  components/
    ChatWidget.tsx
supabase/
  functions/
    chat/
      index.ts          — Edge Function
  migrations/
    [timestamp]_chat_schema.sql
```

---

## TASK CODE GENERATION GUIDE
*(Michael reads this section when generating CODE for PRD tasks)*

**Schema task:**
Use SQL from SUPABASE SCHEMA section.
Include the `increment_chat_rate_limit` RPC function.
RUN: `supabase db push`
VERIFY: `supabase db execute --sql "SELECT table_name FROM information_schema.tables WHERE table_name LIKE '%message%' OR table_name LIKE '%conversation%'"`
Expected: conversations, messages, chat_rate_limits, chat_system_prompts.

**Edge Function task:**
Use Edge Function template above.
Set ANTHROPIC_API_KEY secret: `supabase secrets set ANTHROPIC_API_KEY=sk-ant-...`
RUN: `supabase functions serve chat`
VERIFY: `curl -X POST http://localhost:54321/functions/v1/chat -H "Content-Type: application/json" -d '{"message":"Hello","sessionToken":"test","clientId":"[id]"}'`
Expected: streaming SSE data with text chunks.

**Chat widget task:**
Use ChatWidget.tsx component above.
Customise: botName, primaryColor, placeholder per client project_brand.
Mount in root layout or specific page as specified in brief.
RUN: `npm run dev` and open chat widget.
VERIFY: sends message, receives streaming response, conversation stored in Supabase.

**System prompt task:**
Insert system prompt into chat_system_prompts table.
Use template from SYSTEM PROMPT TEMPLATE section.
Fill in client-specific: company name, services, CTA, tone.
RUN: `supabase db execute --sql "SELECT * FROM chat_system_prompts WHERE client_id='[id]'"`
VERIFY: row exists with correct prompt content.

**Rate limit task:**
Test: send 51 messages with same session token.
RUN: loop of curl requests.
VERIFY: 51st message returns 429 status.
