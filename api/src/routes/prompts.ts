import type { FastifyInstance } from 'fastify'
import { createPrompt, getPromptBySlug, updatePrompt, getPromptByDeviceId } from '../db.js'

export function registerPromptRoutes(app: FastifyInstance) {
  // POST /v1/prompts — create or update a prompt
  app.post<{
    Body: { device_id: string; prompt_text: string; slug?: string }
  }>('/v1/prompts', async (request, reply) => {
    const { device_id, prompt_text, slug } = request.body

    if (!device_id || !prompt_text) {
      return reply.code(400).send({ error: 'device_id and prompt_text required' })
    }

    // Check if device already has a prompt — update it
    const existing = getPromptByDeviceId(device_id)
    if (existing) {
      const updated = updatePrompt(existing.slug, device_id, prompt_text)
      return {
        slug: updated!.slug,
        url: `${request.protocol}://${request.hostname}/${updated!.slug}`,
        created: false,
      }
    }

    // Create new
    const prompt = createPrompt(device_id, prompt_text, slug)
    return {
      slug: prompt.slug,
      url: `${request.protocol}://${request.hostname}/${prompt.slug}`,
      created: true,
    }
  })

  // PUT /v1/prompts/:slug — update an existing prompt
  app.put<{
    Params: { slug: string }
    Body: { device_id: string; prompt_text: string }
  }>('/v1/prompts/:slug', async (request, reply) => {
    const { device_id, prompt_text } = request.body

    if (!device_id || !prompt_text) {
      return reply.code(400).send({ error: 'device_id and prompt_text required' })
    }

    const updated = updatePrompt(request.params.slug, device_id, prompt_text)
    if (!updated) {
      return reply.code(404).send({ error: 'Not found or unauthorized' })
    }

    return {
      slug: updated.slug,
      url: `${request.protocol}://${request.hostname}/${updated.slug}`,
    }
  })

  // GET /v1/prompts/:slug — get prompt data (JSON)
  app.get<{ Params: { slug: string } }>('/v1/prompts/:slug', async (request, reply) => {
    const prompt = getPromptBySlug(request.params.slug)
    if (!prompt) {
      return reply.code(404).send({ error: 'Not found' })
    }

    return {
      slug: prompt.slug,
      prompt_text: prompt.prompt_text,
      updated_at: prompt.updated_at,
    }
  })

  // GET /:slug — serve a web page with the prompt
  app.get<{ Params: { slug: string } }>('/:slug', async (request, reply) => {
    const { slug } = request.params

    // Skip health check and other system routes
    if (slug === 'health' || slug === 'v1') {
      return reply.code(404).send({ error: 'Not found' })
    }

    const prompt = getPromptBySlug(slug)
    if (!prompt) {
      return reply.code(404).type('text/html').send(notFoundPage())
    }

    return reply.type('text/html').send(promptPage(prompt.prompt_text, slug, prompt.updated_at))
  })
}

function promptPage(promptText: string, slug: string, updatedAt: string): string {
  const escaped = promptText
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Voice Prompt — BARkey</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
      background: #FAF5F0;
      color: #262421;
      min-height: 100vh;
      padding: 24px;
    }
    .container { max-width: 640px; margin: 0 auto; }
    .header {
      text-align: center;
      margin-bottom: 24px;
    }
    .header h1 {
      font-size: 20px;
      font-weight: 800;
      letter-spacing: -0.5px;
    }
    .header p {
      font-size: 13px;
      color: #595553;
      margin-top: 4px;
    }
    .prompt-box {
      background: white;
      border-radius: 16px;
      padding: 20px;
      box-shadow: 0 2px 12px rgba(0,0,0,0.04);
      white-space: pre-wrap;
      font-family: 'SF Mono', 'Menlo', 'Consolas', monospace;
      font-size: 13px;
      line-height: 1.6;
      color: #262421;
      max-height: 60vh;
      overflow-y: auto;
    }
    .actions {
      margin-top: 16px;
      display: flex;
      gap: 12px;
    }
    .btn {
      flex: 1;
      padding: 14px;
      border: none;
      border-radius: 12px;
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s;
    }
    .btn-primary {
      background: #FF6B35;
      color: white;
    }
    .btn-primary:hover { background: #e55a2a; }
    .btn-primary.copied {
      background: #34C759;
    }
    .footer {
      text-align: center;
      margin-top: 32px;
      font-size: 12px;
      color: #595553;
    }
    .footer a { color: #FF6B35; text-decoration: none; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>BARkey Voice Prompt</h1>
      <p>Paste this into any LLM's system prompt to write in this voice.</p>
    </div>
    <div class="prompt-box" id="prompt">${escaped}</div>
    <div class="actions">
      <button class="btn btn-primary" id="copyBtn" onclick="copyPrompt()">Copy to Clipboard</button>
    </div>
    <div class="footer">
      <p>Generated with <a href="https://barkey.app">BARkey</a> · Updated ${new Date(updatedAt).toLocaleDateString()}</p>
    </div>
  </div>
  <script>
    function copyPrompt() {
      const text = document.getElementById('prompt').innerText;
      navigator.clipboard.writeText(text).then(() => {
        const btn = document.getElementById('copyBtn');
        btn.textContent = 'Copied!';
        btn.classList.add('copied');
        setTimeout(() => {
          btn.textContent = 'Copy to Clipboard';
          btn.classList.remove('copied');
        }, 2000);
      });
    }
  </script>
</body>
</html>`
}

function notFoundPage(): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Not Found — BARkey</title>
  <style>
    body {
      font-family: -apple-system, system-ui, sans-serif;
      background: #FAF5F0;
      color: #262421;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      text-align: center;
    }
    h1 { font-size: 48px; margin-bottom: 8px; }
    p { color: #595553; }
  </style>
</head>
<body>
  <div>
    <h1>404</h1>
    <p>This voice prompt doesn't exist.</p>
  </div>
</body>
</html>`
}
