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

**Status:** building
**Last updated:** 2026-03-15
**iOS build:** 16 on TestFlight (target temporarily lowered to 10 for testing)
**API:** `https://barkey-api-988719556625.us-east1.run.app` (Cloud Run, live)
**What just shipped:**
- Custom AppleAutocompleteService: UITextChecker + 50 contractions + 70 typo corrections + 150 bigram next-word predictions + retroactive word fixing
- Message capture via text proxy polling (works across all apps, not just iMessage)
- Raw message storage in MessageStore (App Group) — messages kept until user exports + burns
- Few-shot prompt generation: 40 real message examples + statistical summary (replaced stats-only V1)
- Message review screen: truncated previews for transparency, swipe to delete, no full text copying
- Shortlink API: POST /v1/prompts → get hosted URL, GET /:slug → branded web page with copy button
- Redesigned home screen: concept explainer, pricing upfront ($9.99), burn philosophy, transparency card
- Dedicated pricing page: value prop, free vs paid tiers, FAQ, anti-app philosophy
- App icon, theme system, onboarding walkthrough
- TestFlight builds 1-16 shipped during session
- GitHub issues: #26 (conversation import), #27 (KeyboardKit Pro eval)
**What's next:**
- Wire StoreKit 2 to gate export behind $9.99 IAP
- Restore targetMessageCount to 500 after testing
- Test full export + shortlink flow on device
- Improve autocorrect quality (add more dictionary entries as Paul reports gaps)
- Custom domain for shortlinks (barkey.app instead of Cloud Run URL)
- Conversation import (#26): WhatsApp export parsing to supplement keyboard capture
**What's blocking:** StoreKit not wired yet — export currently ungated. Autocorrect quality is usable but noticeably below Apple's native keyboard (no ML-based predictions).

## Success Metrics
<!-- OWNER CONTEXT — keep success criteria evidence-based and task-aligned -->

(Paul to define — suggested: blind test where someone can't tell if Paul or the LLM wrote a message)
