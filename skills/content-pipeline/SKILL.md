---
name: content-pipeline
description: Generate content (blog posts, social, web copy, emails) from briefs. Use when you need to produce written content for marketing, communications, or publishing.
---

# Content Pipeline Skill

## Activation Checklist

When this skill is loaded/activated:

1. **Confirm workspace** - Ensure `~/Projects/content` exists. Create if not: `mkdir -p ~/Projects/content`
2. **Say**: "content-pipeline loaded. Send me a brief."

## When Receiving a Brief

### Step 1: Identify Content Type

Determine what type of content is needed:

- **Blog post** - Long-form article, typically 800-2000+ words
- **Social** - Short-form posts (Twitter/X, LinkedIn, Instagram captions)
- **Web copy** - Landing pages, about pages, product descriptions
- **Email** - Newsletters, outreach, announcements

### Step 2: Generate Full Content

Produce content according to the brief, including:

- **Headline** - Compelling, on-brand title
- **Body** - Full content matching the brief's requirements
- **Call to action** - Clear next step for the reader

### Step 3: Save Output

1. Create project folder: `mkdir -p ~/Projects/content/[project-name]/`
2. Save as markdown: `~/Projects/content/[project-name]/content.md`
3. Include metadata at top (content type, date, brief summary)

### Step 4: Return

- File path to saved content
- Preview of the content (headline + first paragraph or key excerpt)

## Notes

- Match tone and style to the brief
- Optimize for the platform (SEO for web, engagement for social, etc.)
- Include formatting (headers, lists, emphasis) for readability
