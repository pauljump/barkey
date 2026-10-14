/**
 * BARkey API — shortlink service for voice prompts
 *
 * POST /v1/prompts — upload a prompt, get a shortlink
 * GET  /v1/prompts/:slug — get prompt JSON
 * GET  /:slug — web page with prompt + copy button
 */

import { createApp, parseEnv } from '@pauljump/api-kit'
import { z } from 'zod'
import { initDb } from './db.js'
import { registerPromptRoutes } from './routes/prompts.js'

const envSchema = z.object({
  PORT: z.coerce.number().default(3000),
  HOST: z.string().default('0.0.0.0'),
  DB_PATH: z.string().default('./data/barkey.db'),
})

const env = parseEnv(envSchema)

initDb(env.DB_PATH)

const app = await createApp({ name: 'barkey-api', port: env.PORT })

registerPromptRoutes(app)

await app.listen({ port: env.PORT, host: env.HOST })
console.log(`BARkey API running on port ${env.PORT}`)
