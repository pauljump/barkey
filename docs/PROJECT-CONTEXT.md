# BARkey — Burn After Reading Keyboard

## What This Is
<!-- OWNER CONTEXT — this is the product vision, not a technical summary -->

iOS keyboard that invisibly captures your writing style over ~500 messages, generates a portable LLM system prompt that mimics your voice, and then you delete the app. "Burn after reading" — the anti-app. No server, no accounts, no stored messages. Everything runs on-device.

Keyboard looks identical to the default iOS keyboard with a small BARkey logo. Free users get a style summary + paste-to-rewrite demo. Paid users ($9.99) get the full prompt + hosted shortlink. Style refresh anytime for $2.99.

## Architecture
<!-- 🔓 AUTO-UPDATE as code changes -->

**100% on-device iOS app. No backend (V1).**

```
┌─────────────────────────────────────────┐
│  iOS Keyboard Extension                 │
│  ┌───────────────┐  ┌────────────────┐  │
│  │ Keystroke      │→│ Statistical    │  │
│  │ Observer       │  │ Engine         │  │
│  │ (in-memory)    │  │ (counters only)│  │
│  └───────────────┘  └───────┬────────┘  │
│                              │           │
│  ┌───────────────────────────▼────────┐  │
│  │ Style Profile (App Group storage)  │  │
│  │ word_freq, bigrams, punctuation,   │  │
│  │ avg_length, caps_ratio, slang_pct  │  │
│  └───────────────────────────┬────────┘  │
│                              │           │
├──────────────────────────────┼───────────┤
│  Containing App              │           │
│  ┌───────────────────────────▼────────┐  │
│  │ Prompt Generator                   │  │
│  │ profile → LLM system prompt text   │  │
│  └───────────────────────────┬────────┘  │
│  ┌───────────────────────────▼────────┐  │
│  │ Progress UI: "247 / 500 messages"  │  │
│  │ Setup Walkthrough (Wispr-quality)  │  │
│  │ Free: paste-to-rewrite demo        │  │
│  │ Paid: export prompt + shortlink    │  │
│  └────────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

Two components:
1. **Keyboard Extension** — visually identical to iOS default keyboard + small BARkey logo. Observes typed text in memory, updates statistical counters via App Group shared storage. Never persists raw text.
2. **Containing App** — setup walkthrough, progress bar, style summary, paste-to-rewrite demo (free), prompt export + shortlink (paid). Minimal UI.

### Key Files
<!-- 🔓 AUTO-UPDATE -->

| File | Purpose |
|------|---------|
| `ios/project.yml` | XcodeGen config — main app + keyboard extension targets |
| `ios/Shared/StyleProfile.swift` | The statistical fingerprint struct — counters only, never raw text |
| `ios/Shared/StyleAnalyzer.swift` | Processes message text into profile updates (in-memory) |
| `ios/Shared/ProfileStore.swift` | App Group read/write for sharing profile between app and keyboard |
| `ios/Shared/PromptGenerator.swift` | Converts StyleProfile → portable LLM system prompt (THE product) |
| `ios/BARkeyKeyboard/KeyboardViewController.swift` | KeyboardKit controller + BARkeyActionHandler (observes keystrokes) |
| `ios/BARkeyApp/Sources/App/BARkeyApp.swift` | @main entry — onboarding → home |
| `ios/BARkeyApp/Sources/App/AppState.swift` | Shared state: profile, onboarding status |
| `ios/BARkeyApp/Sources/App/Theme.swift` | BARkey brand colors (ember, ash, smoke, charcoal) |
| `ios/BARkeyApp/Sources/Views/OnboardingView.swift` | 4-step walkthrough: welcome → privacy → enable keyboard → live |
| `ios/BARkeyApp/Sources/Views/HomeView.swift` | Progress ring, style summary, try/export actions |
| `ios/BARkeyApp/Sources/Views/ExportView.swift` | Full prompt display + copy to clipboard |
| `ios/BARkeyApp/Sources/Views/RewriteView.swift` | Free tier: paste text → see style analysis preview |

### Stack
<!-- 🔓 AUTO-UPDATE -->

- Swift / SwiftUI (containing app)
- KeyboardKit 10.3+ (SPM — renders native-looking keyboard, handles key layout/gestures/feedback)
- App Groups (shared data between keyboard extension and containing app)
- StoreKit 2 ($9.99 export, $2.99 refresh) — not yet wired
- V2: LLM-powered prompt generation (Claude or GPT-4o via lightweight API)

## Build & Run
<!-- 🔓 AUTO-UPDATE -->

```bash
# Generate Xcode project
cd barkey/ios
xcodegen generate

# Build for simulator
xcodebuild build -project BARkey.xcodeproj -scheme BARkey \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet

# Note: keyboard extensions have limited simulator support
# Full testing requires a physical device (enable keyboard in Settings)
```

## What Runs Where
<!-- 🔓 AUTO-UPDATE -->

| Component | Environment | URL/Location |
|-----------|-------------|--------------|
| iOS App + Keyboard | User's iPhone | App Store (eventually) |
| Backend | None (V1) | N/A — fully on-device |

## External Dependencies
<!-- 🔓 AUTO-UPDATE -->

- **KeyboardKit** (SPM, v10.3+) — keyboard rendering framework. Free tier for core keyboard. Closed-source binary (XCFramework).
- V1 has no server dependencies. V2 will add a lightweight API for LLM-powered prompt generation.

## Design Principles
<!-- OWNER CONTEXT — these are product decisions -->

- **Burn after reading** — the product succeeds when the user deletes it
- **Nothing leaves the device** — no server, no analytics, no accounts, no telemetry
- **Messages are never stored** — not on device, not anywhere. Only statistical counters persist.
- **The prompt is the product** — everything else is scaffolding
- **Keyboard must be invisible** — identical to iOS default, just a small logo. Users should forget they switched.
- **Setup walkthrough is the product** — if users can't enable the keyboard, nothing else matters. Wispr-quality onboarding.
- **Transparency is the brand** — show users exactly what we track and what we don't. No fine print.

## What NOT to Build
<!-- OWNER CONTEXT — preserve product intent; update with evidence or explicit task direction -->

(Paul to confirm)

## Critical Gotchas
<!-- 🔓 AUTO-UPDATE — add here when you hit something painful -->

- iOS keyboard extensions have strict memory limits (~30-50MB) — the statistical engine must be lightweight
- Keyboard extensions run in a separate process from the containing app — communication via App Groups
- "Allow Full Access" is required for the keyboard to process text — this is the trust barrier
- Apple may scrutinize keyboard extensions that "analyze" typing — App Store review positioning matters
- Keyboard extension must look identical to default iOS keyboard — any visual difference = user friction

## Naming Conventions
<!-- 🔓 AUTO-UPDATE as patterns emerge -->

**Name: BARkey** (Burn After Reading Keyboard). Bundle ID: `com.barkey.app`. Keyboard extension: `com.barkey.app.keyboard`.

## Current State
<!-- 🔓 AUTO-UPDATE every session -->

**Status:** TestFlight beta
**Last updated:** 2026-10-14
**iOS build:** 1.0 (20)
**API:** retired. The Cloud Run shortlink service no longer exists; the app has no server.

**2026-10-14 pass (build 20):**
- Capture fixed: sent = same field empties with no recent backspace; drafts, field switches and pre-existing text ignored; search/URL/login/code/card/address fields skipped; Pause switch
- `CaptureFilter` blanks emails, links, long numbers before storage; 1,000-message cap; dedupe
- Autocorrect no longer forces ambiguous contractions (were/its/well/ill/id/…) and leaves slang, learned words, mid-sentence names alone; removed the duplicate retroactive fixer
- Shortlink upload removed; export = Copy / Share; privacy copy made true (onboarding said messages were never stored — they were)
- Try Your Voice (rewrite / reply) and Spot the Fake (blind test) on Apple's on-device FoundationModels
- Live keyboard + Full Access checklist; first prompt at 50 messages, best at 200
- Beta is free; StoreKit still not wired

**What's next:** device test of capture in iMessage/WhatsApp; App Review guideline 4.4.1 (keyboards may only collect activity to improve the keyboard) is the open risk for public release; StoreKit.

## Success Metrics
<!-- OWNER CONTEXT — keep success criteria evidence-based and task-aligned -->

Blind test: the person can't tell their real messages from ones written with their prompt (Spot the Fake in-app).
