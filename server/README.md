# BARkey voice server

Lets an assistant write like you without copy-paste. The BARkey app encrypts your voice prompt on the phone and
publishes only the ciphertext here; the key travels in the link you give your assistant.

```
node server.mjs            # PORT=8520 HOST=127.0.0.1 PUBLIC_URL=https://barkey.polyfeeds.dev BARKEY_STATE=~/Library/Application Support/barkey-voice
node test.mjs              # end-to-end: encrypt, publish, read via REST/page/MCP, wrong key, wrong owner, burn
```

| Route | Who | What |
|---|---|---|
| `PUT /v1/voices/:id` (Bearer owner token) | the app | create or replace `{ciphertext, nonce}` |
| `DELETE /v1/voices/:id` (Bearer owner token) | the app | burn |
| `GET /v1/voices/:id/:key` | Muse custom connector, any REST client | `{voice, instructions, updatedAt}` |
| `GET /v/:id/:key` | anything that reads a page | markdown |
| `POST /mcp/:id/:key` | Claude, ChatGPT, MCP clients | streamable HTTP, JSON responses; tools `my_voice`, `write_like_me`; resource `barkey://voice` |
| `GET /`, `/llms.txt`, `/skill.md`, `/privacy`, `/health` | people and agents | how to use it |

Zero dependencies. State is one JSON file per voice holding ciphertext, nonce, the owner token's SHA-256 and an
updated time. Decryption (AES-256-GCM) happens in memory per request. 60 requests a minute per IP.

Deploy per `kit/playbooks/local-dev-deploy.md`: fleet registry entry `barkey-voice` (always-on, port 8520, cap
128M, health `/health`), tunnel ingress + CNAME for `barkey.polyfeeds.dev`.
