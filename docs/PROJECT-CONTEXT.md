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
- KeyboardKit 10.9 free (SPM binary — keyboard surface, gestures, feedback). Autocorrect is BARkeyEngine, not KeyboardKit's.
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

**Status:** production pass in progress (build 22, local commits, not yet uploaded)
**Last updated:** 2026-10-26
**iOS build:** 1.0 (22)

**2026-10-26 pass (build 22):**
- Autocorrect rebuilt as `ios/Packages/BARkeyEngine` (pure Swift, tested on the Mac): SCOWL+Google-Books lexicon trie
  (90k words with frequencies), A* decoder with a QWERTY key-distance slip model (neighbour, missed, extra, swapped keys,
  dropped apostrophes), Witten-Bell language model over corpus phrases + the person's own messages, correction policy
  (never touch known words except dwarfed contractions like "cant"; junk word-list entries like "rhe" are correctable;
  names, handles, URLs, numbers, deliberate casing, texting words and owned words are protected). Fat-finger benchmark
  (`swift run -c release barkey-eval`): 73–78% of single slips fixed, 0 of ~1,000 clean words ruined, ~0.7 ms/word.
- KeyboardKit 10.3 → 10.9.7 (free). Needed `SWIFT_ENABLE_EXPLICIT_MODULES: NO` for its LicenseKit dependency on Xcode 27.
- Feel settings on: character previews, haptics + clicks (default on first launch), autocap, double-space period,
  hold-space cursor. Backspace right after a correction reverts it and keeps the word (shared `KeptWords`); tapping the
  typed word in the bar keeps it too.
- "Write like me" without copy-paste: (1) keyboard shortcut word (default `myvoice`) + space types a 12-example voice brief
  into any app (Dot, Muse…); (2) `server/` voice server: app encrypts the prompt (AES-GCM, CryptoKit, key in Keychain),
  server stores ciphertext only; MCP (Claude/ChatGPT), REST JSON (Muse custom connector), markdown page. ConnectView in app.
  Auto-refresh after 25 new messages. Burn deletes server copy. Server tests pass (`node server/test.mjs`).
- Home screen: "Try the keyboard" field, "Use It in Your Assistants" action.
- Verified live in the simulator (BARkeyUITests, both pass): "teh " → "The ", backspace right after puts "teh " back, "lol" untouched, double-space period + sentence caps ("Hi there. Ok"). Corrections are applied synchronously on space/punctuation (`tryApplyAutocorrectSuggestion` override), so a fast thumb can't outrun the bar. Gotchas: a custom keyboard's keys are invisible to XCUITest (tap by the system keyboard's key frames); the "Next keyboard" button's value names the *next* keyboard; keyboard-extension debug trail = `kb_debug` in the App Group plist (Debug builds).
- Deployment of `barkey-voice` (fleet registry, tunnel ingress, CNAME barkey.polyfeeds.dev, port 8520) prepared but
  NOT applied: blocked pending Paul's explicit go.

**What's next:** Paul types on build 22 (installed on PJ iPhone via devicectl); deploy barkey-voice; TestFlight upload
(`ios/ship-testflight.sh`); App Review 4.4.1 wording; StoreKit decision.

## Success Metrics
<!-- OWNER CONTEXT — keep success criteria evidence-based and task-aligned -->

Blind test: the person can't tell their real messages from ones written with their prompt (Spot the Fake in-app).
