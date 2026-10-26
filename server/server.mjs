// BARkey voice server: lets an assistant write like you without copy-paste.
//
// The app encrypts your voice prompt on the phone (AES-256-GCM) and publishes only the ciphertext here, under a
// random id. The key never reaches this server at rest: it travels in the URL you give your assistant, and the
// server decrypts in memory per request. Delete (burn) and the ciphertext is gone.
//
//   PUT    /v1/voices/:id            body {ciphertext, nonce}  (bearer = owner token)   create or replace
//   DELETE /v1/voices/:id            (bearer = owner token)                             burn
//   GET    /v1/voices/:id/:key       JSON {voice, updatedAt}       for Muse custom connectors and any REST client
//   GET    /v/:id/:key               text/markdown                 a page any assistant can read
//   POST   /mcp/:id/:key             MCP streamable HTTP (tools: my_voice, write_like_me)   for Claude, ChatGPT
//   GET    /llms.txt, /skill.md, /   how to use it
//
// Zero dependencies. State: $BARKEY_STATE/voices/<id>.json (ciphertext only).

import http from 'node:http'
import { createDecipheriv, createHash, timingSafeEqual } from 'node:crypto'
import { mkdirSync, readFileSync, writeFileSync, unlinkSync, existsSync } from 'node:fs'
import { join } from 'node:path'

const PORT = Number(process.env.PORT || 8520)
const HOST = process.env.HOST || '127.0.0.1'
const PUBLIC_URL = process.env.PUBLIC_URL || 'https://barkey.polyfeeds.dev'
const STATE = process.env.BARKEY_STATE || join(process.env.HOME, 'Library/Application Support/barkey-voice')
const MAX_BODY = 256 * 1024
const MAX_VOICES = Number(process.env.BARKEY_MAX_VOICES || 5000)
mkdirSync(join(STATE, 'voices'), { recursive: true })

const idPattern = /^[A-Za-z0-9_-]{16,64}$/
const keyPattern = /^[A-Za-z0-9_-]{40,48}$/ // 32 bytes base64url

function voicePath(id) { return join(STATE, 'voices', `${id}.json`) }
function sha(s) { return createHash('sha256').update(s).digest('hex') }
function b64url(s) { return Buffer.from(s.replace(/-/g, '+').replace(/_/g, '/'), 'base64') }

function readVoice(id) {
  if (!idPattern.test(id) || !existsSync(voicePath(id))) return null
  try { return JSON.parse(readFileSync(voicePath(id), 'utf8')) } catch { return null }
}

/// Decrypts in memory. The record stores {ciphertext, nonce} base64url and the owner token's hash.
function decrypt(record, key) {
  try {
    const keyBytes = b64url(key)
    if (keyBytes.length !== 32) return null
    const data = b64url(record.ciphertext)
    const nonce = b64url(record.nonce)
    const tag = data.subarray(data.length - 16)
    const body = data.subarray(0, data.length - 16)
    const d = createDecipheriv('aes-256-gcm', keyBytes, nonce)
    d.setAuthTag(tag)
    return Buffer.concat([d.update(body), d.final()]).toString('utf8')
  } catch { return null }
}

function send(res, status, body, type = 'application/json', extra = {}) {
  const out = typeof body === 'string' ? body : JSON.stringify(body)
  res.writeHead(status, { 'content-type': type + '; charset=utf-8', 'cache-control': 'no-store', 'access-control-allow-origin': '*', ...extra })
  res.end(out)
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let size = 0; const chunks = []
    req.on('data', c => { size += c.length; if (size > MAX_BODY) { reject(new Error('too large')); req.destroy() } else chunks.push(c) })
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')))
    req.on('error', reject)
  })
}

function bearer(req) {
  const h = req.headers.authorization || ''
  return h.startsWith('Bearer ') ? h.slice(7).trim() : null
}

// Simple per-IP limiter: 60 requests a minute.
const hits = new Map()
function limited(ip) {
  const now = Date.now(); const slot = hits.get(ip) || []
  const recent = slot.filter(t => now - t < 60_000); recent.push(now); hits.set(ip, recent)
  if (hits.size > 10_000) hits.clear()
  return recent.length > 60
}

const INSTRUCTIONS = (voice) => `You are writing as this person. Below is their voice, built from messages they actually sent. Match it: length, capitalization, punctuation, slang, openers. Never add ideas they did not give you. Never copy an example word for word.\n\n${voice}`

function voiceTools() {
  return [
    {
      name: 'my_voice',
      description: "This person's writing voice, built on their iPhone from messages they really sent. Call it before drafting anything they will send as themselves (texts, emails, posts, replies). Follow it exactly.",
      inputSchema: { type: 'object', properties: {}, additionalProperties: false },
    },
    {
      name: 'write_like_me',
      description: 'Returns the voice plus the text to rewrite or the situation to answer, framed as instructions. Use when asked to "write this like me", "reply as me" or "make this sound like me".',
      inputSchema: { type: 'object', properties: { text: { type: 'string', description: 'The draft to rewrite, or the message to reply to.' }, mode: { type: 'string', enum: ['rewrite', 'reply', 'draft'], description: 'rewrite the text in their voice, reply to it as them, or draft something new about it' } }, required: ['text'] },
    },
  ]
}

function mcpResponse(id, result) { return { jsonrpc: '2.0', id, result } }
function mcpError(id, code, message) { return { jsonrpc: '2.0', id, error: { code, message } } }

async function handleMcp(req, res, record, key) {
  if (req.method === 'GET') return send(res, 405, mcpError(null, -32000, 'Use POST (streamable HTTP, JSON responses).'))
  if (req.method !== 'POST') return send(res, 405, mcpError(null, -32000, 'POST only'))
  let msg
  try { msg = JSON.parse(await readBody(req)) } catch { return send(res, 400, mcpError(null, -32700, 'Parse error')) }
  const messages = Array.isArray(msg) ? msg : [msg]
  const replies = []
  for (const m of messages) {
    if (!m || m.jsonrpc !== '2.0') { replies.push(mcpError(m?.id ?? null, -32600, 'Invalid request')); continue }
    if (m.id === undefined) continue // notification
    switch (m.method) {
      case 'initialize':
        replies.push(mcpResponse(m.id, { protocolVersion: m.params?.protocolVersion || '2025-06-18', capabilities: { tools: {}, resources: {} }, serverInfo: { name: 'BARkey voice', version: '1.0.0' }, instructions: 'Call my_voice before writing anything this person will send as themselves, and follow it exactly.' }))
        break
      case 'ping': replies.push(mcpResponse(m.id, {})); break
      case 'tools/list': replies.push(mcpResponse(m.id, { tools: voiceTools() })); break
      case 'resources/list': replies.push(mcpResponse(m.id, { resources: [{ uri: 'barkey://voice', name: 'My voice', description: "This person's writing voice", mimeType: 'text/markdown' }] })); break
      case 'resources/read': {
        const voice = decrypt(record, key)
        if (!voice) { replies.push(mcpError(m.id, -32002, 'Voice unavailable')); break }
        replies.push(mcpResponse(m.id, { contents: [{ uri: 'barkey://voice', mimeType: 'text/markdown', text: voice }] }))
        break
      }
      case 'tools/call': {
        const voice = decrypt(record, key)
        if (!voice) { replies.push(mcpResponse(m.id, { content: [{ type: 'text', text: 'This voice has been burned or the link is wrong.' }], isError: true })); break }
        const name = m.params?.name; const args = m.params?.arguments || {}
        if (name === 'my_voice') replies.push(mcpResponse(m.id, { content: [{ type: 'text', text: INSTRUCTIONS(voice) }] }))
        else if (name === 'write_like_me') {
          const mode = args.mode || 'rewrite'
          const task = mode === 'reply' ? `Someone sent this person the message below. Write the reply they would send. Output only the reply.\n\nMessage:\n${args.text}`
            : mode === 'draft' ? `Write what this person would send about the following. Output only the message.\n\n${args.text}`
            : `Rewrite the message below the way this person would write it. Keep the meaning and facts. Output only the rewritten message.\n\nMessage:\n${args.text}`
          replies.push(mcpResponse(m.id, { content: [{ type: 'text', text: `${INSTRUCTIONS(voice)}\n\n---\n\n${task}` }] }))
        } else replies.push(mcpError(m.id, -32602, `Unknown tool ${name}`))
        break
      }
      default: replies.push(mcpError(m.id, -32601, `Method not found: ${m.method}`))
    }
  }
  if (replies.length === 0) return send(res, 202, '')
  send(res, 200, Array.isArray(msg) ? replies : replies[0])
}

const HOME_MD = `# BARkey voice

BARkey is an iPhone keyboard that learns how you text and turns it into a "write like me" voice. This server lets your assistant use that voice directly.

Your BARkey app gives you one private link. Give it to your assistant:

- Claude, ChatGPT and other MCP clients: add \`${PUBLIC_URL}/mcp/<id>/<key>\` as a connector. Tools: \`my_voice\`, \`write_like_me\`.
- Muse: ask Muse to build a custom connector for \`${PUBLIC_URL}/v1/voices/<id>/<key>\` (GET, JSON, field \`voice\`).
- Anything that can read a page: \`${PUBLIC_URL}/v/<id>/<key>\`.

The voice is stored here encrypted. The key is only in your link. Burn it in the app and it is gone.

Privacy: ${PUBLIC_URL}/privacy. Source: https://github.com/pauljump/barkey
`

const server = http.createServer(async (req, res) => {
  const ip = req.headers['cf-connecting-ip'] || req.socket.remoteAddress || ''
  if (limited(ip)) return send(res, 429, { error: 'slow down' })
  const url = new URL(req.url, PUBLIC_URL)
  const parts = url.pathname.split('/').filter(Boolean)
  if (req.method === 'OPTIONS') return send(res, 204, '', 'text/plain', { 'access-control-allow-methods': 'GET,PUT,DELETE,POST,OPTIONS', 'access-control-allow-headers': 'authorization,content-type,mcp-protocol-version,mcp-session-id' })
  try {
    if (parts.length === 0 || parts[0] === 'llms.txt' || parts[0] === 'skill.md') return send(res, 200, HOME_MD, 'text/markdown')
    if (parts[0] === 'health') return send(res, 200, { ok: true })
    if (parts[0] === 'privacy') return send(res, 200, readFileSync(new URL('../PRIVACY.md', import.meta.url), 'utf8'), 'text/markdown')

    if (parts[0] === 'v1' && parts[1] === 'voices' && parts[2]) {
      const id = parts[2]
      if (!idPattern.test(id)) return send(res, 400, { error: 'bad id' })
      if (req.method === 'PUT') {
        const token = bearer(req)
        if (!token || token.length < 32) return send(res, 401, { error: 'owner token required' })
        let body
        try { body = JSON.parse(await readBody(req)) } catch { return send(res, 400, { error: 'bad body' }) }
        if (typeof body.ciphertext !== 'string' || typeof body.nonce !== 'string' || body.ciphertext.length > 200_000) return send(res, 400, { error: 'ciphertext and nonce required' })
        const existing = readVoice(id)
        if (existing && !timingSafeEqual(Buffer.from(existing.owner), Buffer.from(sha(token)))) return send(res, 403, { error: 'not yours' })
        if (!existing) {
          const count = (await import('node:fs')).readdirSync(join(STATE, 'voices')).length
          if (count >= MAX_VOICES) return send(res, 507, { error: 'full' })
        }
        writeFileSync(voicePath(id), JSON.stringify({ ciphertext: body.ciphertext, nonce: body.nonce, owner: sha(token), updatedAt: new Date().toISOString() }))
        return send(res, 200, { ok: true, mcp: `${PUBLIC_URL}/mcp/${id}/<key>`, rest: `${PUBLIC_URL}/v1/voices/${id}/<key>`, page: `${PUBLIC_URL}/v/${id}/<key>` })
      }
      if (req.method === 'DELETE') {
        const token = bearer(req)
        const existing = readVoice(id)
        if (!existing) return send(res, 200, { ok: true, gone: true })
        if (!token || !timingSafeEqual(Buffer.from(existing.owner), Buffer.from(sha(token)))) return send(res, 403, { error: 'not yours' })
        unlinkSync(voicePath(id))
        return send(res, 200, { ok: true, gone: true })
      }
      if (req.method === 'GET' && parts[3]) {
        const record = readVoice(id)
        const voice = record && keyPattern.test(parts[3]) ? decrypt(record, parts[3]) : null
        if (!voice) return send(res, 404, { error: 'no such voice' })
        return send(res, 200, { voice, instructions: INSTRUCTIONS(voice), updatedAt: record.updatedAt })
      }
      return send(res, 405, { error: 'method' })
    }

    if (parts[0] === 'v' && parts[1] && parts[2]) {
      const record = readVoice(parts[1])
      const voice = record && keyPattern.test(parts[2]) ? decrypt(record, parts[2]) : null
      if (!voice) return send(res, 404, 'No such voice. It may have been burned.', 'text/plain')
      return send(res, 200, `# Write like me\n\n${INSTRUCTIONS(voice)}\n`, 'text/markdown')
    }

    if (parts[0] === 'mcp' && parts[1] && parts[2]) {
      const record = readVoice(parts[1])
      if (!record || !keyPattern.test(parts[2])) return send(res, 404, mcpError(null, -32000, 'No such voice'))
      return handleMcp(req, res, record, parts[2])
    }

    send(res, 404, { error: 'not found' })
  } catch (error) {
    send(res, 500, { error: String(error.message || error) })
  }
})

server.listen(PORT, HOST, () => console.log(`barkey-voice on http://${HOST}:${PORT} state ${STATE}`))
