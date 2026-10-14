import { getDb } from '@pauljump/api-kit'
import type Database from 'better-sqlite3'
import crypto from 'node:crypto'

const SETUP_SQL = `
  CREATE TABLE IF NOT EXISTS prompts (
    slug TEXT PRIMARY KEY,
    device_id TEXT NOT NULL,
    prompt_text TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
  );

  CREATE INDEX IF NOT EXISTS idx_prompts_device ON prompts(device_id);
`

let db: Database.Database

export function initDb(path?: string): Database.Database {
  db = getDb({ path: path || './data/barkey.db', setup: SETUP_SQL })
  return db
}

function getDatabase(): Database.Database {
  if (!db) throw new Error('Database not initialized')
  return db
}

function randomSlug(): string {
  return crypto.randomBytes(4).toString('hex') // 8 chars
}

// ── Prompt helpers ──

export interface Prompt {
  slug: string
  device_id: string
  prompt_text: string
  created_at: string
  updated_at: string
}

export function getPromptBySlug(slug: string): Prompt | undefined {
  return getDatabase()
    .prepare('SELECT * FROM prompts WHERE slug = ?')
    .get(slug) as Prompt | undefined
}

export function getPromptByDeviceId(deviceId: string): Prompt | undefined {
  return getDatabase()
    .prepare('SELECT * FROM prompts WHERE device_id = ? ORDER BY updated_at DESC LIMIT 1')
    .get(deviceId) as Prompt | undefined
}

export function createPrompt(deviceId: string, promptText: string, preferredSlug?: string): Prompt {
  const db = getDatabase()
  let slug = preferredSlug || randomSlug()

  // If preferred slug is taken, fall back to random
  if (preferredSlug) {
    const existing = getPromptBySlug(preferredSlug)
    if (existing && existing.device_id !== deviceId) {
      slug = randomSlug()
    }
  }

  // Upsert — if this device already has a prompt at this slug, update it
  const existing = getPromptBySlug(slug)
  if (existing && existing.device_id === deviceId) {
    db.prepare(
      `UPDATE prompts SET prompt_text = ?, updated_at = datetime('now') WHERE slug = ?`
    ).run(promptText, slug)
  } else {
    db.prepare(
      'INSERT INTO prompts (slug, device_id, prompt_text) VALUES (?, ?, ?)'
    ).run(slug, deviceId, promptText)
  }

  return getPromptBySlug(slug)!
}

export function updatePrompt(slug: string, deviceId: string, promptText: string): Prompt | null {
  const existing = getPromptBySlug(slug)
  if (!existing || existing.device_id !== deviceId) return null

  getDatabase().prepare(
    `UPDATE prompts SET prompt_text = ?, updated_at = datetime('now') WHERE slug = ?`
  ).run(promptText, slug)

  return getPromptBySlug(slug)!
}
