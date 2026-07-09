# MCP Response Parsing (SSE / JSON-RPC)

## Response Format

MCP (Model Context Protocol) servers return responses in **SSE (Server-Sent Events)** format, not plain JSON. Each event line starts with `data:`.

## Parsing SSE from a Raw Response

```python
raw = resp.read().decode()
for event_line in raw.split('\n'):
    if line.startswith('data:'):
        data = json.loads(line[5:])  # strip 'data:' prefix
```

Multiple events may be in one response separated by `\n\n`.

## Content Wrapping (Important)

MCP tool responses wrap their output in a `content[].text` envelope, not directly in the `result` key:

```json
{
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"id\":\"...\",\"title\":\"...\",\"url\":\"...\"}"
      }
    ]
  }
}
```

The actual data is `result.content[0].text` as a **JSON string** that must be parsed again:

```python
def parse_mcp_text(result):
    text = result.get('content', [{}])[0].get('text', '{}')
    return json.loads(text)
```

## List Documents Response

`list_documents` returns documents under `content[].text.document`:

```python
for item in result.get('content', []):
    text = json.loads(item['text'])
    doc = text.get('document', text)  # may be nested under 'document'
```

## Common MCP Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| `json.decoder.JSONDecodeError: Expecting value: line 1 column 1` | Response is SSE, not JSON | Parse line-by-line looking for `data:` prefix |
| `dict has no key 'title'` | Data is in `content[0].text` as JSON string | Double-parse: first from content envelope, then the JSON string itself |
| Empty `content: []` | No items returned (empty collection, no results) | Not an error — check length before accessing [0] |
| `Not Acceptable` (error -32000) | Missing `text/event-stream` in Accept header | Set `Accept: application/json, text/event-stream` |
