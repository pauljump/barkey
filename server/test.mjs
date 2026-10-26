// End-to-end test against a local server: encrypt like the app, publish, read back through REST, page and MCP, burn.
import { randomBytes, createCipheriv } from 'node:crypto'
import { spawn } from 'node:child_process'
import { mkdtempSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import assert from 'node:assert/strict'

const state = mkdtempSync(join(tmpdir(), 'barkey-voice-'))
const port = 8599
const child = spawn('node', [new URL('./server.mjs', import.meta.url).pathname], { env: { ...process.env, PORT: String(port), BARKEY_STATE: state, PUBLIC_URL: `http://127.0.0.1:${port}` }, stdio: ['ignore', 'pipe', 'inherit'] })
await new Promise(r => child.stdout.once('data', r))
const base = `http://127.0.0.1:${port}`
const b64url = b => b.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
try {
  const key = randomBytes(32), nonce = randomBytes(12), id = b64url(randomBytes(16)), owner = b64url(randomBytes(32))
  const voice = '## Real Examples\n- "omw home now"\n- "yeah that works"\n'
  const c = createCipheriv('aes-256-gcm', key, nonce)
  const ct = Buffer.concat([c.update(voice, 'utf8'), c.final(), c.getAuthTag()])
  let r = await fetch(`${base}/v1/voices/${id}`, { method: 'PUT', headers: { authorization: `Bearer ${owner}`, 'content-type': 'application/json' }, body: JSON.stringify({ ciphertext: b64url(ct), nonce: b64url(nonce) }) })
  assert.equal(r.status, 200)
  r = await fetch(`${base}/v1/voices/${id}/${b64url(key)}`); assert.equal(r.status, 200)
  assert.equal((await r.json()).voice, voice)
  r = await fetch(`${base}/v1/voices/${id}/${b64url(randomBytes(32))}`); assert.equal(r.status, 404, 'wrong key is a 404')
  r = await fetch(`${base}/v/${id}/${b64url(key)}`); assert.match(await r.text(), /omw home now/)
  r = await fetch(`${base}/mcp/${id}/${b64url(key)}`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: '2025-06-18' } }) })
  assert.equal((await r.json()).result.serverInfo.name, 'BARkey voice')
  r = await fetch(`${base}/mcp/${id}/${b64url(key)}`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ jsonrpc: '2.0', id: 2, method: 'tools/list' }) })
  assert.deepEqual((await r.json()).result.tools.map(t => t.name), ['my_voice', 'write_like_me'])
  r = await fetch(`${base}/mcp/${id}/${b64url(key)}`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ jsonrpc: '2.0', id: 3, method: 'tools/call', params: { name: 'write_like_me', arguments: { text: 'can you come', mode: 'reply' } } }) })
  const text = (await r.json()).result.content[0].text
  assert.match(text, /omw home now/); assert.match(text, /can you come/)
  r = await fetch(`${base}/v1/voices/${id}`, { method: 'PUT', headers: { authorization: `Bearer ${b64url(randomBytes(32))}`, 'content-type': 'application/json' }, body: JSON.stringify({ ciphertext: 'x', nonce: 'y' }) })
  assert.equal(r.status, 403, 'another owner cannot overwrite')
  r = await fetch(`${base}/v1/voices/${id}`, { method: 'DELETE', headers: { authorization: `Bearer ${owner}` } }); assert.equal(r.status, 200)
  r = await fetch(`${base}/v/${id}/${b64url(key)}`); assert.equal(r.status, 404, 'burned')
  console.log('voice server: all checks passed')
} finally { child.kill() }
