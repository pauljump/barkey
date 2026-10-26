# BARkey history digest

Compiled 2026-10-26 from the usual-recall index of Claude Code and Codex sessions, the repo
(`projects/barkey`), the stale copy (`_factory/barkey`), git history, and memory notes.
Session ids are usual-recall ids (first 8 chars shown, full ids in the timeline).

**Coverage gap.** The original BARkey build (March 2026: builds 1-16, the Cloud Run shortlink
service, the KeyboardKit autocorrect) is not in the recall index. Claude Code auto-deleted
pre-July transcripts (memory `never-delete-session-history`, 10-01), and no Codex session before
2026-09 mentions BARkey at all. What we know about March comes from
`_factory/barkey/PROJECT-CONTEXT.md` (last updated 2026-03-15) and the monorepo git log.

---

## 1. Timeline

| Date | Where | What happened |
|---|---|---|
| 2026-03 (to 03-15) | No transcript. `_factory/barkey/PROJECT-CONTEXT.md` | Original build, in `/Users/mini-home/Desktop/Monorepo/barkey`. Concept: "iOS keyboard that invisibly captures your writing style over ~500 messages, generates a portable LLM system prompt that mimics your voice, and then you delete the app." KeyboardKit 10.3 free tier. V1 was counters-only (StyleProfile: word_freq, bigrams, punctuation, caps_ratio, slang_pct); replaced during the session by raw message storage in an App Group `MessageStore` + few-shot prompt (40 real examples + stats). Custom `AppleAutocompleteService`: UITextChecker + 50 contractions + 70 typo fixes + 150 bigram next-word predictions + retroactive word fixing. Capture via text-proxy polling. Shortlink API on Cloud Run (`barkey-api-988719556625.us-east1.run.app`, POST /v1/prompts, GET /:slug branded page). Pricing page: $9.99 export + hosted shortlink, $2.99 refresh. TestFlight builds 1-16. GitHub issues #26 (conversation import, WhatsApp export) and #27 (evaluate KeyboardKit Pro). Noted blocker: "Autocorrect quality is usable but noticeably below Apple's native keyboard (no ML-based predictions)." StoreKit never wired; export ungated. targetMessageCount temporarily lowered 500 -> 10 for testing. |
| 2026-04-27 | `_factory` git `5ac1278d` | Monorepo initial commit includes `barkey/`. |
| 2026-06-19 | `_factory` git `894994b1` | Build bump 16 -> 17 for TestFlight re-upload (with BooWho). No product change. |
| 2026-08-08/09 | `_factory` git | Agent-policy normalization only (AGENTS.md/CLAUDE.md). |
| 2026-07/08 | codex a5eb23f6, d1c73e7a, e4fb338a, 011f81dc and others | These sessions are about the **Unhinged** dating app and the **write-like-paul Codex skill** (`~/.codex/skills/write-like-paul`), not BARkey. The skill retrieves Paul's authored X posts + transcripts to draft text in his voice; it is the Mac-side sibling of what BARkey tries to do on the phone. Paul used it constantly ("[$write-like-paul] no dashes no colons", "way too long … much shorter"). No BARkey mention. |
| 2026-09-12 | codex 8820ab94 | Usual menu planning: "a generalized version of Write Like Paul" proposed as a Usual item. |
| 2026-09-21 | claude bb9fb9f0 | TestFlight team-wide expiry; all 21 apps re-uploaded. BARkey build 18 VALID. |
| 2026-09-29 | claude 750299cc | Portfolio audit: "Three built iOS apps are one payment hookup away from charging. Barkey ($9.99 once), Chomp and Dinder…" |
| 2026-10-12 19:15 -> 10-13 01:49 | claude 0d562bdf4fbd7213e6e0af64b0616cd7712bc0b467aad86d450cfab34e7b3d7d | Telegraph/Usual keyboard research session. Paul wants a one-thumb keyboard "faster than thinking" on Jev. First-letter decoding failed (22% words). Pivot to key words -> brief. Then 23:08 "the keyboard needs to be apple otherwise", 23:09 "I thought we had a version though with barkey ai", 23:30 "No we bought something or downloaded something for barkey" (research: nothing bought; KeyboardKit free). 00:15 decision: "take the keyboard kit starting with the alterations I made to it already with barkey and make improvements … fix my fat fingers … 'finish' button … no swapping keyboards." Confirmed KeyboardKit free ignores custom views -> Finish button needs KeyboardKit Pro (price unpublished, Gumroad) or a different base. |
| 2026-10-13 01:48 -> 11:19 | codex 497510007416a6e88a3a0a462b197b9324957ff93fb4d0295494d355ecf9eb8f | Usual keyboard mission (Codex high). No KeyboardKit Pro key -> built on **hex-keyboard** (MIT) + JBoard swipe decoder. Builds 3-8 on PJ iPhone. Scorecard numbers below. Paul 02:32: "the actual keyboard feels so different from Apple native. It types too far from accurate… They need to not think they switched keyboards at all." 02:49: "its ok. Not the best but better than it was before. Still no swipe text." 04:32: "Its ok but still nit there." 05:02: "I think its much better. But think you need to autocorrect… The keyboardnthatbis. Also… the corpus… Its like very Claude session specific" (91% of corpus words came from agent prompts). |
| 2026-10-14 16:25 -> 10-15 12:25 | claude d699e34156942dd2ceecf14560c7a7016f7717b9e0d0f57f29a87266d7c7bc5b | Verhum/Turrii trigger. 16:38 "create a repo for barkey that I can share with the group." 16:42 "get barkey uploaded to TestFlight. Do a true pass on its functionality and improve it significantly prior." Graduated to `projects/barkey`, public at github.com/pauljump/barkey (snapshot "build 16 era", then the build 20 pass). Landscape research + two teek jams on proof-of-human writing. Build 20 upload hung (orphan AWAITING_UPLOAD in ASC); build 21 uploaded via Apple cloud signing after the shared signing keychain password stopped working; VALID 17:35. Public TestFlight link + beta review **never approved** by Paul (he answered an unrelated question; agent explicitly did not treat "Ok" as approval). |
| 2026-10-14 18:26 -> 10-15 21:28 | codex 236fe92841713b06876ab0c3732972d7524ad1181ae3d1a68dfb056044d00a1b | Turrii jam + standalone Turrii keyboard prototype (`projects/turrii-keyboard`, pushed to github.com/Verhum/paul). First Turrii keyboard was hand-built UIKit; 19:16 Paul: "dude the keyboard itself is rotten. you need to get a keyboard that barkey was using. it's at least usable." Codex ported BARkey's KeyboardKit surface + autocomplete (Turrii builds 4-5), then on 20:12 dropped KeyboardKit for its own state machine (build 7). Bugs along the way listed in section 3. |
| 2026-10-26 10:55 | claude 9dbaa5077b10bbf5ecc4b1342ea08ce80131fde5ef8359c550f32ab6b9f7ab5a | "Research all barkey conversations… get this app to production readiness. Let's even think though mcp so it's no longer a copy paste but a true write like me experience especially in muse and dot… the keyboard works as well as an iOS keyboard." This digest is part of that run. |

---

## 2. Paul's stated requirements and wishes (verbatim where short)

### The keyboard feel (the gate)
- "the keyboard needs to be apple otherwise. Like the auto predict and swipe etc." (0d562bdf, 10-12 23:08)
- "there is no swipe to text. There is no autocorrect and the letter don't show haptics or anything" (0d562bdf, 10-12 23:29, about the first hand-built Usual keyboard)
- "They work ok." / "It's just not as good. You mean to tell me no one cracked this. Would it be easier for you or codex to go heads down to get a close clone?" (0d562bdf, 10-13 00:06-00:07, after trying hex-keyboard and jboard)
- "the main thing is like the thing Apple does well fix my fat fingers. Like I make a lot of typos but it fixes the typos mid sentence or so. I think we'll almost be encouraging typos because we'll sort of have a 'finish' button. There will be no swapping keyboards for that button" (0d562bdf, 10-13 00:15)
- Mission brief he approved (497510, 10-13 01:48): "key feel, key pop-ups, haptics, sentence capitals, and fixing his fat-finger typos as he goes, mid-sentence, the way Apple does. His word for the open-source attempts so far was 'not as good'; beat that." Also: "corrections use his vocabulary (names, slang, project words…), not just a generic dictionary."
- "the actual keyboard feels so different from Apple native. It types too far from accurate and that's one of the most important things. They need to not think they switched keyboards at all." (497510, 10-13 02:32)
- "Still no swipe text." (497510, 10-13 02:49). After swipe added: "Its ok but still nit there. You need to research and take finding from all over to fix." (04:32)
- "you need to autocorrect… The keyboardnthatbis [= 'keyboard that is', joined words]" (497510, 10-13 05:02)
- "dude the keyboard itself is rotten. you need to get a keyboard that barkey was using. it's at least usable." (236fe928, 10-15 19:16). Meaning: BARkey's KeyboardKit-based keyboard is Paul's floor for "usable"; a hand-rolled UIKit keyboard without native-sized keys, repeat delete, proper shift and symbol layers is "rotten".
- Turrii keyboard complaints that define "real": "first it's all caps. next it doesn't let me look for an symbols like and apostrphe… how do we get the keyboard to be more real" (236fe928, 10-15 20:08); "backspace doesnt work well especially if there's a line break" (21:14); "we actually dont need the autocomplete suggestions on this" (19:52, Turrii only).
- 10-26: "making sure that the keyboard works as well as an iOS keyboard. Do everything you can to make that work perfectly."
- Earlier (March) design principle: "Keyboard must be invisible, identical to iOS default, just a small logo. Users should forget they switched."

### Capture rules
- March: capture ~500 messages (target lowered to 10 for testing, never restored before 10-14), never persist raw text (V1), then reversed to store raw messages until export + burn.
- 10-14 pass (Paul asked for "a true pass on its functionality"): sent = same field empties with no recent backspace; ignore drafts, field switches, pre-existing text; skip search/URL/login/code/card/address fields; blank emails, links, long numbers; 1,000-message cap; dedupe; Pause switch; Burn everything; review list with swipe-delete. First prompt at 50 messages, best at 200.

### Prompt quality
- March: few-shot prompt = 40 real examples + statistical summary (replaced stats-only V1 because stats alone did not sound like him).
- Success metric (PROJECT-CONTEXT): "Blind test: the person can't tell their real messages from ones written with their prompt (Spot the Fake in-app)." Built 10-14 on Apple FoundationModels (device only; simulator has no model assets).
- Codex 10-14 (236fe928 18:27) flagged that Spot the Fake must be "genuinely diagnostic" rather than "a satisfying demo"; not resolved.
- Usual mission: "It never adds ideas he didn't type"; corrections and rewrites must keep "his exact words, slang, names and meaning."

### Privacy
- March: "Nothing leaves the device, no server, no analytics, no accounts, no telemetry" was the stated principle, but the shortlink upload sent the prompt to Cloud Run and onboarding said messages were never stored when they were. 10-14 fixed both: shortlink removed, PRIVACY.md added, copy "made true".
- Full Access is required and explained in PRIVACY.md; the app shows a live keyboard + Full Access checklist.
- Jams (d699e341) consensus on the Turrii direction: never hold raw keystroke/process data; show facts, not a human score.

### Pricing
- March: free = style summary + paste-to-rewrite demo; paid $9.99 = full prompt + hosted shortlink; $2.99 style refresh. StoreKit 2 never wired (still true at build 21). 10-14: "Beta is free."
- 09-29 audit called it "one payment hookup away from charging."

### Distribution
- 10-14: "create a repo for barkey that I can share with the group" (done, public). "Maybe if we could share a download without TestFlight… host whatever on a Tryusual site" (answered: only TestFlight public link, Ad Hoc, or build-it-yourself). "Ok get me GitHub link I can share saved let's get on TestFlight." Build 21 VALID; public link and beta review await explicit go.
- App Review risk: guideline 4.4.1 (keyboards may only collect activity to improve the keyboard). Flagged 10-14, unresolved.

---

## 3. Bugs and complaints, and status

| Bug / complaint | Where | Status |
|---|---|---|
| Autocorrect "noticeably below Apple's native keyboard" | March PROJECT-CONTEXT | Open. Still UITextChecker + hand lists. |
| Autocorrect forced contractions ("were"->"we're", "its"->"it's", "well"->"we'll") and rewrote slang/names, "rewriting the very voice it was there to capture" | d699e341 10-14 | Fixed in build 20 (ambiguous contractions left alone, slang and learned words left alone, duplicate retroactive fixer removed). |
| Capture saved deleted drafts, leftover text, previous chat's draft on field switch | d699e341 10-14 | Fixed in build 20 (send detection). |
| Onboarding claimed messages never stored | d699e341 10-14 | Fixed (copy made true). |
| Cloud Run shortlink service gone; app still tried to upload | d699e341 10-14 | Fixed (upload removed; `api/` kept as history). |
| Build 20 TestFlight upload hung at AWAITING_UPLOAD | d699e341 10-14 17:09 | Worked around: build 21 uploaded via cloud signing. Orphan 20 record remains in ASC. |
| Shared distribution signing keychain password no longer unlocks it (changed 10-11) | d699e341 | Worked around (ASC API key cloud signing in `ios/ship-testflight.sh`); keychain itself unresolved. |
| Try Your Voice / Spot the Fake fail on simulator ("no underlying assets") | d699e341 | Expected; device-only. Friendlier error added. Never device-tested by Paul. |
| targetMessageCount lowered to 10 for testing | March | Superseded: 10-14 set first prompt at 50, best at 200. |
| StoreKit not wired, export ungated | March | Open. |
| Usual/hex keyboard: same tap gave different letters depending on prediction timing (7.4% of 324k synthetic taps reassigned) | 497510 10-13 02:39 | Fixed in Usual build 5 (0% reassignment). |
| Usual: Undo stayed enabled after new typing | 497510 02:26 | Fixed. |
| Usual: network Finish could overwrite newer typing | 497510 01:49 | Fixed (stale-response guard). |
| Usual: corpus 91% agent prompts, 9% sent messages | 497510 05:05 | Fixed (message-led corpus); gain small (85.7->85.9 light, 75.7->77.3 heavy). |
| Usual: iOS 26 blurred the suggestion strip (scroll view edge effect) | 0d562bdf 10-12 22:42 | Fixed (edge effect off). |
| Turrii kb: crashed on select because KeyboardKit/LicenseKit frameworks not embedded in IPA | 236fe928 10-15 19:40 | Fixed build 5 (then KeyboardKit dropped in build 7). |
| Turrii kb: all caps stuck, no apostrophe/symbols layer, not purple, typewriter icon | 236fe928 20:08-20:10 | Fixed build 7 (own state machine). |
| Turrii kb: backspace across line breaks | 236fe928 21:14 | Fix claimed before iPhone install; unverified by Paul. |
| KeyboardKit free ignores custom toolbar/views | 0d562bdf 10-13 00:22 | Confirmed limit; blocks a Finish/Rephrase key inside a KeyboardKit keyboard without Pro. |

Measured keyboard numbers worth keeping (497510, held-out, Paul's real messages with synthetic typos):
- hex autocorrect: 85.7% words right (light), 75.7% (heavy); with corpus fix 85.9 / 77.3.
- Finish (Haiku, personalized): 88.5 / 83.5, ~1 s, 18/40 and 13/40 whole messages exact.
- Swipe (JBoard decoder + context): 95.8 / 91.1 synthetic; only 54.6% on real human swipe traces.
- Mission acceptance targets were never met; Codex marked the mission "blocked, not complete."

---

## 4. Decisions made and reversed

| Decision | Then |
|---|---|
| V1 "statistical counters only, never raw text" (March) | Reversed in March: raw messages stored in App Group until burn, because few-shot examples beat stats. |
| Hosted shortlink on Cloud Run, $9.99 | Service died; removed 10-14. Export = Copy / Share only. "API: retired." |
| 500-message target | Lowered to 10 for testing; 10-14 reset to 50 first / 200 best. |
| Usual keyboard = fork of BARkey's KeyboardKit keyboard + Finish (10-13 00:15) | Reversed within hours: KeyboardKit free can't host a Finish key; built on hex-keyboard instead. Paul's feel verdict: "ok… still not there." |
| Turrii keyboard hand-built UIKit (10-15 18:15) | "rotten"; reverted to BARkey's KeyboardKit surface (builds 4-5); then reversed again to a dependency-free state machine (build 7) because KeyboardKit "owns keyboard state" and shift/layers broke. |
| Proof-of-human / provenance features belong in BARkey? | Jams and Codex both said no: belongs in Usual (which already performs AI edits) or in a separate Turrii repo. Paul: "we'd want to keep it seperate. this project shouldnt get tangled with the things i solely own." BARkey stays "write like me". |
| TestFlight public link | Prepared 10-14, never approved. Paul's 10-26 ask ("production readiness") supersedes but still does not itself authorize submission. |
| `_factory/barkey` | Stale duplicate since 10-14; not yet symlinked. |

---

## 5. "Write like me" via MCP / agents (Muse, Dot, ChatGPT, Claude)

Direct BARkey + MCP discussion exists only in Paul's 10-26 ask: "think though mcp so it's no longer a copy paste but a true write like me experience especially in muse and dot." Nothing earlier wires BARkey's prompt to an assistant; the product has always ended at Copy / Share of a prompt.

Relevant prior art in Paul's own sessions:
- **write-like-paul Codex skill** (`~/.codex/skills/write-like-paul/SKILL.md`, used from at least 2026-08-11 onward, dozens of sessions): retrieves authored X posts + transcript evidence via `retrieve_voice.py --topic`, infers "pace, directness, framing, certainty", never imitates surface quirks, forbids quoting private material publicly. Paul's recurring constraints: "no dashes no colons", "all lower case" for X, "much shorter", "get rid of all the slop writing… hemingway really" (a6fa7ebc 08-11). 09-18 (claude 51d97904): "codex has a write-like-paul skill. i wonder if you could take that and apply it to the writing we've done on the site." This is the Mac-side model for what a BARkey MCP would expose: a voice-evidence retrieval tool, not a static prompt.
- **anyagent / First Date adapter** (claude 09ef3795, 10-01; memory `anyagent-connector`, `first-date-by-agent`): one definition -> MCP endpoint + MCP Apps card for Claude/ChatGPT, text-only for Grok, `skill.md` + REST for Muse, `/d/<code>.md` pages for Instinct (which can't take connectors). Paul: "What if we actually built an adapter?" This is the existing pattern for reaching Muse.
- **Muse custom connectors** (claude eb5fe02b, 09-25): Muse can add a connector from a public streamable-HTTP MCP URL; server must be publicly reachable (Meta cloud). Memory `switchboard`: "Muse owns the customer, we do the job."
- **Both Answers / Meet via Muse** (e1ebaf2e 09-25/26): Muse writes a brief "from what it knows about them… the person sees all of it and approves it before it goes in." Same consent shape a voice prompt needs.
- **Dot**: appears only in the 10-26 ask and in "people are just gonna ask muse and dot and grokbot to tell them what to do" (19aead6d, 10-26 04:20). No prior technical notes on Dot connectors in the index.
- Codex 09-12 (8820ab94): proposed "a generalized version of Write Like Paul" as a Usual menu item.
- Thiel jam take (d699e341): "The scarce thing isn't human labor. It's legitimate delegation… impersonation by someone else's model of you." Supports exposing the voice as an authorized, revocable resource rather than a pasted string.

Constraint from BARkey's own promise: "no server, no account" and "burn after reading". A public MCP endpoint for Muse means the prompt (or an on-demand voice resource) leaves the phone and needs hosting plus an owner key; Instinct needs plain pages. That tension is undecided.

---

## 6. Open questions

1. Keyboard base: stay on KeyboardKit free (Paul's "usable" floor, no custom keys), buy KeyboardKit Pro (price unknown, needed for in-keyboard buttons and its autocomplete engine), or own state machine (Turrii build 7 route, dependency-free, more work for Apple parity)? Paul has never been happy with any option yet.
2. What exactly makes Apple's feel: fat-finger correction mid-sentence, pop-ups, haptics, sentence caps, repeat delete, apostrophe/symbol layers, backspace across newlines, no swipe (platform limit, Paul keeps asking). Which of these does build 21 actually do on device? Paul has not typed on build 21.
3. App Review 4.4.1: keyboards may only collect activity to improve the keyboard. BARkey stores sent messages for a prompt. Risk at public release; no mitigation chosen.
4. StoreKit: $9.99 / $2.99 pricing is in copy but never wired; beta is free. Charge or stay free?
5. MCP shape for Muse/Dot: hosted prompt endpoint vs on-demand voice tool; who hosts; owner key; how it squares with "no server, burn after reading"; Instinct needs plain pages.
6. Spot the Fake: is it diagnostic or a demo (Codex 10-14 doubt)? Not device-tested.
7. TestFlight: build 21 VALID; public link + beta review need Paul's explicit go. Orphan build 20 record in ASC.
8. `_factory/barkey` stale copy; replace with symlink and commit.
9. March transcripts are gone; GitHub issues #26 (conversation import) and #27 (KeyboardKit Pro eval) referenced in PROJECT-CONTEXT were not found in current repos (0d562bdf research).
