# BARkey — Burn After Reading Keyboard

An iPhone keyboard that learns how you text, writes you a portable "write like me" prompt for
any AI, and then asks to be deleted.

You use BARkey as your keyboard for a while. Each message you send is saved on your iPhone, with
emails, links and long numbers blanked out first. From 50 messages, BARkey turns them into a
system prompt that makes ChatGPT, Claude or Gemini write in your voice: your length, your
capitalization, your slang, your openers. Copy it, burn the messages, delete the app.

There is no server, no account and no analytics. Nothing leaves the phone unless you copy or
share the prompt yourself.

## What's in the TestFlight build

- **The keyboard.** Looks like the stock iOS keyboard with BARkey's own autocorrect. Captures a
  message only when it's actually sent: a field that empties without backspacing. It skips search
  bars, address bars, logins, codes, card numbers and addresses, and has a Pause switch.
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
| `ios/BARkeyKeyboard/KeyboardViewController.swift` | When a message counts as sent, and which fields are skipped |
| `ios/Shared/PromptGenerator.swift` | Messages → voice prompt |
| `api/` | Retired shortlink service from the March build. Not used by the app; kept for history |
| `research/` | Landscape of proof-of-human-writing products (Turrii and others) |
| `jams/` | Two persona jams on what to build in that space and how |
| `docs/PROJECT-CONTEXT.md` | Product history and design notes |

Build: `cd ios && xcodegen generate && open BARkey.xcodeproj`. Uses
[KeyboardKit](https://github.com/KeyboardKit/KeyboardKit) 10.3 (free tier). Signing uses the
owner's team; change `DEVELOPMENT_TEAM` in `ios/project.yml` to build your own.

## Why "burn after reading"

Most apps want you forever. BARkey succeeds when you don't need it: the prompt is the product,
and once you have it, the keyboard has done its job.

A note from the research in this repo: BARkey's prompt is exactly the tool that defeats
"proof you're human" products like Turrii. That tension is the subject of the two jams.
