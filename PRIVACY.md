# BARkey privacy policy

_Last updated: October 26, 2026_

BARkey has no accounts and no analytics. Nothing you type is sent anywhere by BARkey unless you turn on the
optional voice link described below.

**What the keyboard saves.** When you send a message in a regular text field, the BARkey keyboard
saves that message on your iPhone, in storage shared only with the BARkey app. Before saving,
email addresses, links and long numbers are replaced with `[email]`, `[link]` and `[number]`.
The keyboard does not save anything typed in search bars, address bars, login, password, code,
card-number or address fields, and saves nothing while capture is paused.

**What the app does with it.** The BARkey app turns your saved messages into a writing-style
prompt, on your iPhone. "Try Your Voice" and "Spot the Fake" run on Apple's on-device model;
nothing is sent to Apple or anyone else for those features.

**Sharing.** The prompt leaves your iPhone only if you copy or share it yourself, type your shortcut word
in another app (the keyboard then types a short version of your voice into that app, on your command), or
turn on the voice link.

**Voice link (optional).** "Use It in Your Assistants" encrypts your prompt on your iPhone (AES-256-GCM) and
uploads only the encrypted copy to barkey.polyfeeds.dev under a random id. The key is never sent to the server
on its own: it is part of the private link you give your assistant, and the server decrypts in memory only when
that link is used. The server stores the encrypted prompt, the time it was updated and a hash of your owner
token, nothing else, and keeps no request logs about you beyond a short-lived rate limit. "Take my voice
offline" (or Burn everything) deletes the copy; every link stops working. The server code is in this repository
(`server/`).

**The keyboard's own corrections.** Autocorrect runs entirely on your iPhone, using a built-in word list and
your own saved messages as vocabulary. Words you keep after undoing a correction are stored with the app's
data on your iPhone only.

**Deleting.** You can view and delete any saved message in the app, or burn them all at once.
Deleting the app deletes everything it saved.

**Full Access.** iOS requires "Allow Full Access" for a keyboard to share data with its own app.
BARkey's keyboard uses it only for that; the keyboard makes no network requests. The app makes network
requests only for the voice link, and only when you turn it on.

Questions: open an issue at https://github.com/pauljump/barkey/issues
