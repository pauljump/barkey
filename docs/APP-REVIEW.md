# App Review notes (draft for build 22)

Paste into App Store Connect → App Review Information → Notes when submitting.

> BARkey is a keyboard that learns the user's own texting style and gives it back to them as a portable
> "write like me" prompt. Everything the keyboard saves stays on the device in the app's own container
> (App Group); there are no accounts, no analytics, and the keyboard itself makes no network requests.
>
> Guideline 4.4.1: the keyboard collects the user's own sent messages only to build the user's personal
> writing profile, which also drives the keyboard's autocorrect and next-word suggestions (their names, slang
> and phrasing are used as vocabulary). Capture is opt-in via Full Access, pausable, reviewable
> (every saved message is listed and deletable) and fully erasable ("Burn everything"). Nothing is sent
> to us. The optional "Use It in Your Assistants" feature uploads an end-to-end-encrypted copy of the
> user's prompt to our server at the user's request; the server cannot read it, and the user can delete it.
>
> To test: add BARkey in Settings → General → Keyboard → Keyboards, enable Full Access, then send a few
> messages in Messages or Notes. The app shows the count; at 50 messages the prompt and the "Try Your
> Voice" / "Spot the Fake" features unlock (those need Apple Intelligence). For a quick look without
> sending 50 messages, the review build accepts the launch argument `-seedDemoOnboarded` in a debug
> build only; the release build does not include demo data, so please use the keyboard normally.
>
> Privacy policy: https://github.com/pauljump/barkey/blob/main/PRIVACY.md

Open risks: 4.4.1 wording above is our position, not a ruling; 5.1.1 (data use) is covered by the
privacy policy and the in-app Review/Burn screens.
