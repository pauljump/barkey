---
topic: "Proof of human writing: how should it work, more efficiently and honestly than Turrii"
date: "2026-10-14"
crew: [bretvictor, collison, thiel]
mode: "autonomous"
project: "barkey"
status: "captured"
---

# Jam: proof of human writing — the how

> **Crew:** Bret Victor (bretvictor), Patrick Collison (collison), Peter Thiel (thiel) · **2026-10-14** · autonomous
> **Framing:** Same brief as `2026-10-14-proof-of-human-what-and-who-pays.md`. Question: concretely, how should proof that a human wrote something work, more efficiently and more honestly than Turrii's keystroke recording + server score + badge?

## Synthesis

**Convergence (all three):** drop the verdict. Turrii's 0–100 server score is the weakest part of its product: timing forgers beat classifiers 99.8%+ of the time (Condrey, Jan 2026), and timing carries no information about whether someone retyped AI text. Claim only what the device observed. Bret Victor: "show what the instrument observed, never what it inferred." Collison: a signed receipt of counts, no "human: 94%". Thiel: claim consent and lineage, not humanity. All three cut the "sounds like you" match score (option C): BARkey's prompt is the forger's tool.

**The three designs:**
- **The Margin (bretvictor):** the message rendered as a signed image, colored by input channel. Solid = tapped, grey = suggestion bar, blue = written by the keyboard's AI, hatched = pasted/unknown. Plus a tap-density strip labeled "texture, not evidence." Readable in one second.
- **Typed Receipt (collison):** a salted hash plus counts (taps, suggested, foreign insertions, span, timing histogram), signed by a Secure Enclave key vouched for by App Attest, logged in a public append-only log, and verified offline in 7 lines. The relying party sets the threshold. The honest name is "typed, not pasted."
- **Voice Notary (thiel):** invert it. Certify that a voice prompt was derived from N messages typed on device K over D days (hash commitment only), and sign text approved through that voice as "written by Paul's authorized voice, approved by Paul." Proof of *authorization*, not humanity. First market: executives and founders who already ghostwrite.

**Dissent:** Thiel says "prove you're human" is a dead end and the business is delegation. Collison and Victor keep the typing facts as useful, as long as nothing beyond them is claimed. Collison flags his own hole: nobody has "verify typed authorship" on their roadmap.

**Shared first tests:** (1) one afternoon on a device: can a keyboard extension sign with a Secure Enclave key? (2) the one-week hand-made receipt test in real threads; (3) a $50 red-team: get a 90%-tapped receipt for LLM text on a stock iPhone; (4) ten relying-party conversations.

**What ships regardless:** Usual's span labels. It is the one place where the AI and the capture surface are the same code, so the label is a fact, not an inference.

**One line:** Sign facts, not verdicts: a receipt or Margin that shows what was tapped, suggested, AI-written or pasted, and, if anything is worth a company, notarize the authorized voice rather than the human pulse.

## The takes

### Bret Victor — show the work, don't issue a verdict

Start with what Turrii gives the reader: a badge and a number, 87 out of 100. That is the system telling the reader what it concluded. The reader can't see the process, and the scoring is hidden on someone else's server. The writing happened, the trace of it was taken away, and the reader gets back a verdict. We are asked to trust the system, which is exactly the habit that the tradition of Engelbart and Kay set out to end. The badge is a dead fish. It reports that something lived and shows none of it.

The replay is the obvious alternative, and it fails in a different way. It is a video, and a video is bound to time. To understand four minutes of composition, the reader has to spend four minutes watching. Nobody watches a replay of a LinkedIn post. The landscape research shows who does: students using Grammarly Authorship or Draftback to answer an accusation. A replay is a defense exhibit. Nobody reads with it. And for a 12-word dating reply, about 60 taps, there is nothing to watch at all.

So "proof" is the wrong frame. Proof assumes a judge and a cheater. The honest frame is the one from the mathematics classroom: *show your work.* We don't do it to defeat forgery. We do it so the reader can see how much of the person is in the thing. Authorship is a gradient: typed, accepted from a suggestion, expanded by a tool, pasted from somewhere unknown. A yes/no badge throws the gradient away.

**The proposal: "the Margin."** When the user sends, the keyboard draws the message as a static image. It runs on the device, uploads nothing, and the device signs the image. The image has two layers.

1. **The text, colored by input channel.** Solid ink means characters the user tapped. Grey means words taken from the keyboard's own suggestion bar. Blue means spans written by Usual's Rephrase or Expand. Hatching means text the keyboard did not put there: paste, Writing Tools, autofill. These are not guesses. The keyboard knows which spans it inserted itself, and anything that changed in the field without its input it can see only as "unknown insertion," which it labels as such.
2. **A strip of tap density along the bottom.** It shows bursts, pauses, and dips where text was deleted. It reads as a portrait of the writing, and the image should say plainly that it is *not* evidence. The landscape cites Condrey (January 2026): fakers that copy human typing rhythms evaded five classifiers at least 99.8% of the time, and for copy-typing, timing carries no information about where the content came from. So timing is shown as texture, and the image should say so in writing on its face.

The principle that divides the world is this: **show what the instrument observed, never what it inferred.** Solid marks are facts. Inferences are left out. Turrii does the reverse. It hides the facts and publishes the inference.

This view is readable in about one second. It doesn't ask the reader to sit through a replay, to click through to a server, or to do any arithmetic.

**On BARkey: the counterfeiter and the mint are in the same building.** BARkey's exported prompt exists to make a model write in your voice. Candidate C in the landscape, the "sounds like you" match score, is therefore self-refuting, and it should be cut. The honest move is design D taken seriously. **A tool that writes for you must show where it wrote.** That is a principle in Tesler's sense: every writing tool either discloses its hand or it doesn't. Usual is the rare case where the AI and the capture surface are the same code, so it can color its own contributions blue, in every app. No Chrome extension can make that claim.

**Falsifiers. Run these before building anything beyond the image renderer:**

- **Calibration.** Show 30 people 20 messages with known ground truth, one third of them with Turrii-style badges and two thirds as Margins. Ask "what share of this did the sender actually write?" If the Margin doesn't cut the error against ground truth by at least half compared with the badge, the representation has failed. Kill it.
- **Glance.** If more than 20% of viewers can't say what the blue spans mean within 5 seconds and without a legend, the encoding is wrong. Redesign the encoding, and do not add a tutorial.
- **Social.** Paul sends Margins in real threads for one week. If no recipient comments on one or asks about one, nobody wants to see the work, and the market is the B2B buyer of the SDK (design E), not the reader.

The honest claim is small: these characters arrived through these channels on this device, and the tool that helped labeled its own help. That claim is enough. Everything beyond it is the kind of theater the autotyper tools already exploit.

**ONE-LINE VERDICT:** Stop issuing verdicts on authorship and draw the text as it was made, solid where the keyboard saw a tap, blue where the tool wrote, hatched where neither knows, so the reader sees the work instead of trusting a score.

### Patrick Collison — ship a signed receipt of facts, not a badge, and let the checker set the threshold

I'll begin with a question I'd ask any founder: who writes the `if` statement? A badge gives a human viewer something to look at. A primitive gives a developer a fact to branch on. Turrii built the badge, and all three parts of its stack point the wrong way:

1. **It records keystrokes.** It stores the raw writing session, which is a liability. Process data is something you should never hold.
2. **It scores on its server.** An unpublished 0–100 number is an oracle you have to trust. Condrey's January 2026 paper reports that timing forgers evaded five classifiers at least 99.8% of the time. So the score is the weakest part of the product, and the product leads with it.
3. **It sells a badge to creators.** Eight installs. Creators are not the buyer.

**The minimal verifiable object is a signed statement of facts, with no verdict.** Call it a *Typed Receipt*:

```
{ h: SHA256(nfc(text) || nonce), taps: 412, suggested: 31, foreign_insertions: 0,
  span_s: 214, iki_hist: [..8 buckets..], device_cert, sig }
```

The fields are counts of how each character got into the field. There's no "human: 94%." The relying party writes the policy, the way a Radar user writes a rule. Verifying should take seven lines and make no network call:

```js
import { verify } from "typed-receipt";
const r = verify(text, receipt, ROOT_PUBKEY);
if (!r.valid) return reject();
if (r.foreign_insertions > 0 || r.taps < text.length * 0.8) flag();
```

The nonce matters. A 12-word dating reply has very little entropy, so an unsalted hash can be brute-forced back to the text.

**Issuance.** The keyboard holds a Secure Enclave P-256 key. The containing app vouches for that key's public half with App Attest, and the server issues a short-lived certificate (24 hours, so revoking a device just means not renewing it). Every receipt goes into a public append-only log, as Certificate Transparency did for TLS. CT did not make bad certificates impossible. It made them *detectable*. That is the honest standard here too.

**Fraud economics: put a price on each attack.**

| Attack | Chrome extension | iOS keyboard |
|---|---|---|
| Paste | ~$0 | Shows up as a foreign insertion. Caught. |
| Software autotyper | ~$0, about 55k users already | No supported way to inject touches. Off the table unless jailbroken. |
| HID injector | Hard to detect | Bypasses the extension, so it shows up as a foreign insertion |
| Retyping LLM text | 10–20× the time cost | Same 10–20× |

So the receipt turns *proof of human authorship* into *proof of human labor*. Labor can be priced. Add velocity limits at the cert issuer: one device cert can't sign more characters per day than a person could tap. That caps a receipt farm at human wages. Call the product "typed, not pasted," never "human-written."

**What's weak in our own proposal:**
- **Option C is nonsense.** BARkey's product is a "write like me" prompt, which *is* the attack.
- **Embedding C2PA in invisible Unicode is fragile.** Carry the receipt outside the text, as a short code, and verify by hash.
- **The Stripe analogy has a hole.** Every developer already had "accept payments" on their roadmap. Which developer has "verify typed authorship" on theirs? A primitive with no one checking it is a format, not an API.

**Falsifiers, cheapest first:**
1. **One afternoon on a device.** Can a keyboard extension with Full Access sign with a Secure Enclave key in a shared keychain group? If not, issuance falls back to trusting a server, and you've rebuilt Turrii.
2. **$50, one week, one red-teamer.** Get a receipt showing at least 90% taps for LLM-generated text on a stock iPhone without retyping. If they manage it, the receipt adds nothing beyond a server log.
3. **Ten relying-party conversations** (a dating app, an assessment vendor, an LMS). If none will write the seven `verify` lines against a hand-signed sample, don't build the issuer.
4. **Usual's span labels** ship regardless. That is the one place where the AI and the capture surface are the same code, so there it is a fact, not an inference.

**ONE-LINE VERDICT:** Don't sell a badge that says "human." Publish a signed, salted, logged receipt that says "these characters were tapped, not pasted," let whoever checks it set the threshold, and kill the project if no one will write the seven lines.

### Peter Thiel — proof of humanity is a forgery race; proof of authorization is the real business

Let me ask the question nobody in this landscape has asked. What would you prove, even if the proof were perfect?

Turrii proves that keys moved at a human pace. That is the labor theory of value applied to prose: the text counts because someone sweated over it. Marx got this wrong about goods, and Turrii gets it wrong about sentences. The research file already contains the proof. Condrey shows that for copy-typing, the mutual information between keystroke timing and where the content came from is *zero*. A person retyping Claude's draft produces a flawless receipt. So the honest ceiling of "typed by a human" is "someone paid a 10–20× time tax." That is a toll. It is not a proof.

Now look at the market structure, because it tells you what you're in. Nineteen entrants. Turrii has 8 users, TrustHuman 5, Human Certified Publisher 6. About 55,000 people use autotypers built to fake the evidence. The attackers outnumber the defenders by thousands to one, and every defender copies the same badge from the others. That is Girard's mimetic crisis in miniature: identical rivals fighting over a prize nobody values. Superhuman already gives process proof away free to 5 million students, and it bought GPTZero. World ID owns personhood through iris scans and Tinder. There is no monopoly left in "prove you're human." There is only a commodity forgery race, and the forgers are improving faster than the provers.

**The secret.** By 2035, most text you send will be drafted by a model of you, and that will be *fine*. Nobody will care whether a human typed a message. They will care whether *you authorized it* and whether the voice is *really yours* rather than a scrape of your LinkedIn. The scarce thing isn't human labor. It's legitimate delegation. The scandal of the next decade is not AI-written messages. It is impersonation by someone else's model of you.

The material admits that BARkey's own product is the attack: it builds the prompt that defeats authorship proofs. Invert that. The attack is the asset. The keyboard is the only party that *witnessed* your real corpus: 500 messages typed by your thumbs on your device over weeks. Nobody else holds that witness position. Not Turrii, not Grammarly on desktop, not World ID.

**Definite plan:**

1. **Kill receipts Options A, B and C as the business.** Before writing code, run the file's own falsifier, open question 5. Paul pastes hand-made receipt links into real threads for 7 days. If fewer than 2 of 20 recipients click, the badge is dead. I predict 0 or 1.
2. **Build the Voice Notary.** BARkey's exported prompt ships with a certificate signed by a Secure Enclave key: "derived from N messages observed typed on device K over D days." Store a hash commitment, never the messages. That keeps burn-after-reading true, which the current build, with its raw MessageStore and Cloud Run shortlinks, quietly is not. Any text produced through that certified prompt and approved by a tap gets signed "written by Paul's authorized voice, approved by Paul." A prompt someone built from scraped posts carries no certificate. This is proof of authorization, not proof of humanity. It is honest because it claims only what it can know: consent and lineage.
3. **Keep Option D (Usual's span labels) as the conscience, not the product.** "You typed 80%, Usual expanded 20%" is truthful disclosure. Truth is a feature, not a moat.
4. **Small market first:** executives and founders who already ghostwrite or AI-write their posts. They have stopped pretending a human typed anything, and they have the most to lose from impersonation. Falsifier: show the certificate to 10 such people. If fewer than 3 say they would require it of their ghostwriter or agent, abandon the thesis.

**Durability.** Here is the uncomfortable part. The natural last mover is Apple. It controls the Secure Enclave, Apple Intelligence and the system keyboard, and it could ship "Signed by you" in an iOS point release. A third-party keyboard is a tenant on Apple's land. The only defensible position is cross-platform portability: a voice certificate that works in Claude, ChatGPT and an email agent, which Apple has no incentive to build. If that portability isn't real within 18 months, this is a feature waiting to be absorbed, and Paul should know that before he spends a quarter on it.

"Prove you're human" is a defensive crouch. Every entrant in this race is backing into the future. The definite question is: in a world of delegated voices, who signs the delegation?

**ONE-LINE VERDICT:** Stop proving that a human pressed the keys, which is a commodity race the forgers win. Certify that the voice is yours and that you authorized it, because the keyboard that watched you write is the only notary for that.
