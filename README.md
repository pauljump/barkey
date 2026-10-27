# BARkey — Burn After Reading Keyboard

An iPhone keyboard that learns how you text, writes you a portable "write like me" prompt for
any AI, and then asks to be deleted.

You use BARkey as your keyboard for a while. Each message you send is saved on your iPhone, with
emails, links and long numbers blanked out first. From 50 messages, BARkey turns them into a
system prompt that makes ChatGPT, Claude or Gemini write in your voice: your length, your
capitalization, your slang, your openers. Copy it, burn the messages, delete the app.

There is no account and no analytics. Nothing leaves the phone unless you copy or share the prompt
yourself, or turn on the optional voice link so your assistants can use it without copy-paste.

## What's in the TestFlight build

- **The keyboard.** Looks and feels like the stock iOS keyboard: key pop-ups, haptics, sentence caps,
  double-space period, hold space to move the cursor. Autocorrect is BARkey's own (`ios/Packages/BARkeyEngine`):
  a 90k-word English lexicon with real frequencies, a QWERTY slip model (neighbour keys, missed, extra and
  swapped keys), corpus phrases for context, and your own sent messages as vocabulary, so your names and
  slang are never "fixed". Backspace right after a correction puts your word back and the keyboard learns it.
  Captures a message only when it's actually sent: a field that empties without backspacing. It skips search
  bars, address bars, logins, codes, card numbers and addresses, and has a Pause switch.
- **Write like me, everywhere.** Type your shortcut word (default `myvoice`) and a space in any app and the
  keyboard types a short version of your voice into the chat. Or create a private link: your prompt is
  encrypted on the phone and your assistants read it directly (MCP for Claude and ChatGPT, a JSON URL for a
  Muse custom connector, a plain page for anything else). Burn it any time.
- **Your voice prompt** (from 50 messages, best at 200). Real examples plus measured style
  (length, punctuation, emoji, slang, openers). Copy or Share.
- **Try Your Voice.** Rewrite a message in your voice, or draft the reply you'd send, using
  Apple's on-device model (iOS 26+ with Apple Intelligence).
- **Spot the Fake.** Three messages you really sent, three the on-device model wrote from your
  prompt. Can you tell which are yours? This is the success test for the prompt.
- **Review and burn.** See every saved message, swipe away any you don't want, or burn them all.

## Setting it up (testers)

1. Install from the TestFlight invite and open BARkey once.
2. Settings → BARkey → Keyboards → turn on **BARkey** and **Allow Full Access**. Full Access is
   what lets the keyboard hand messages to the app; the app shows a live checklist.
3. In any app, hold the 🌐 key and pick BARkey. Text normally.
4. Check the app now and then. At 50 messages, tap **Get Your Voice Prompt**.

Known limits: third-party keyboards can't do swipe typing or dictation, and iOS switches to the
system keyboard in password fields. Try Your Voice and Spot the Fake need Apple Intelligence.

## Repo

| Path | What |
|---|---|
| `ios/` | XcodeGen project: app (`BARkeyApp/`), keyboard extension (`BARkeyKeyboard/`), shared code (`Shared/`) |
| `ios/Shared/CaptureFilter.swift` | What gets blanked or dropped before anything is saved |
| `ios/BARkeyKeyboard/KeyboardViewController.swift` | When a message counts as sent, which fields are skipped, undo-on-backspace, the voice shortcut |
| `ios/BARkeyKeyboard/BARkeyAutocompleteService.swift` | Feeds the engine's suggestions to KeyboardKit |
| `ios/Packages/BARkeyEngine/` | The autocorrect engine (pure Swift, `swift test`; `swift run -c release barkey-eval` for the fat-finger benchmark) |
| `ios/BARkeyUITests/` + `ios/qa/sim-keyboard.sh` | Simulator tests that type on the real BARkey keyboard (adds it in Settings, switches with Next keyboard, taps by key geometry). `qa/sim-keyboard.sh <udid>` then `xcodebuild test -scheme BARkey -only-testing:BARkeyUITests -collect-test-diagnostics never` |
| `server/` | The voice server (zero-dependency Node): encrypted prompts, MCP + REST + page. `node test.mjs` |
| `ios/Shared/PromptGenerator.swift` | Messages → voice prompt |
| `api/` | Retired shortlink service from the March build. Not used by the app; kept for history |
| `research/` | Landscape of proof-of-human-writing products (Turrii and others) |
| `jams/` | Two persona jams on what to build in that space and how |
| `docs/PROJECT-CONTEXT.md` | Product history and design notes |

Build: `cd ios && xcodegen generate && open BARkey.xcodeproj`. Uses
[KeyboardKit](https://github.com/KeyboardKit/KeyboardKit) 10.9 (free tier) for the keyboard surface; autocorrect
is BARkey's own. Word list and phrase data: SCOWL + Google Books fiction n-grams (see
`ios/Packages/BARkeyEngine/NOTICE.md`). Signing uses the
owner's team; change `DEVELOPMENT_TEAM` in `ios/project.yml` to build your own.

## Why "burn after reading"

Most apps want you forever. BARkey succeeds when you don't need it: the prompt is the product,
and once you have it, the keyboard has done its job.

A note from the research in this repo: BARkey's prompt is exactly the tool that defeats
"proof you're human" products like Turrii. That tension is the subject of the two jams.
