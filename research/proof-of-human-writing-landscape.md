# Proof of human writing: landscape, attacks, demand, and the iOS keyboard angle

Research date: 2026-10-14. Sources: web search and fetch, plus local reads of BARkey and Usual keyboard. No paid APIs were called. "(vendor)" means a company-reported figure. "(unverified)" means I found it only in secondary or aggregator sources. Chrome Web Store (CWS) user counts were scraped from listing pages on 2026-10-14.

## 1. Landscape

Turrii in brief: the extension records keystrokes on LinkedIn and Substack and scores each post from 0 to 100. Each proof gets a public page at `turrii.com/v/<id>`. Per its [privacy policy](https://turrii.com/privacy-policy) (June 3, 2026), Turrii stores "writing-session activity" and "signed text" on its servers. A public proof page "may also show a replay of how the text was typed, including corrections," and the author can turn that replay off. KYC runs through unnamed vendors, auth through Clerk, and payments through Stripe. The [CWS listing](https://chromewebstore.google.com/detail/not-slop/ehepplfbhnceoabcejdckhkebfgiilab) shows **8 users**, v0.2.5, updated Oct 7, 2026. The [Verhum GitHub org](https://github.com/Verhum) has one Go repo ("burnrate"), and [ver-hum.com](https://ver-hum.com) describes the team as "tech insiders" who also run burnthemtokens.com.

| Name | Mechanism | Surface | Price | Who buys | Traction |
|---|---|---|---|---|---|
| **Turrii** (ex not-slop, Verifiably Human) | Keystroke capture, a 0–100 score, a signed proof ID, a public page with optional replay, and a KYC badge | Desktop Chrome on LinkedIn and Substack; mobile "in development" | Free (1k chars/mo), $2.99, $5.99 | Creators | 8 CWS users |
| **Grammarly (now Superhuman) Authorship** | Tags each span as typed, pasted from the web, pasted from elsewhere, or Grammarly AI; includes replay ([how it works](https://www.grammarly.com/blog/product/grammarly-authorship/)) | Google Docs via extension, Word desktop, Grammarly Docs, Canvas and Blackboard | **Free** in the Free and Pro plans ([page](https://www.grammarly.com/authorship)) | Students show it to instructors; institutions | More than 5M reports, about 75k a week during the school year (vendor, [Blackboard post](https://www.grammarly.com/blog/product/grammarly-authorship-is-now-available-in-blackboard/)) |
| **GPTZero Origin / Writing Replay** | Google Docs history replay, a "human writing pattern" report, and a detector | Chrome extension and Docs add-on | Freemium; report tier unclear | Teachers, students | 500k CWS users. **Superhuman acquired GPTZero on Jun 23, 2026**; the company claims $30M ARR and 19M registered users ([Engadget](https://engadget.com/2200290/superhuman-has-acquired-ai-authenticity-service-gptzero), [BetaKit](https://betakit.com/?p=407082)) |
| **Draftback** | Replays Google Docs revision history locally | Chrome | Free | Teachers | 400k CWS users, 2.8★ |
| **Brisk "Inspect Writing"** | Docs replay plus a separate AI-detect button ([page](https://www.briskteaching.com/ai-tools/inspect-writing)) | Chrome | Teacher freemium | K-12 teachers | 1M CWS users (whole extension) |
| **Originality.ai "Watch a Writer Write"** | Docs replay; claims to flag autotypers ([page](https://originality.ai/extensions)) | Chrome and Firefox | Credit-based | Content agencies, publishers | 50k CWS users |
| **Turnitin Clarity** | Monitored composition space showing pastes, total time, and draft playback ([press](https://www.turnitin.co.uk/press/turnitin-launches-turnitin-clarity-bringing-transparency-and-integrity-insights-to-education)) | Web, through the LMS | Paid add-on to Feedback Studio; Clarity price not published. Core product runs $2.59–$6.70 per student per year ([CalMatters/Markup](https://themarkup.org/artificial-intelligence/2025/06/26/plagiarism-detector-costs-california)) | Universities | Launched Mar 2025; UCLA still piloting through Spring 2026 ([UCLA](https://dts.ucla.edu/initiatives/bruin-learn-center-excellence/academic-tech-tools/turnitin-clarity)) |
| **Cursive** | Moodle editor plugin: keystroke JSON and replay are free; typing-biometric identity is a paid API ([plugin](https://moodle.org/plugins/tiny_cursive)) | Moodle | Free plugin plus paid API | Institutions | 50+ installs, 2M words validated in H1 2025 (vendor, [EdTech Chronicle](https://edtechchronicle.com/cursive-technology-reaches-50-moodle-installations-and-2-million-words-validated-in-first-half-of-2025/)) |
| **HackerRank / CoderPad** | Keystroke replay, paste and tab-exit events, and an LLM-code classifier ([HackerRank](https://hackerrank-knowledge-base.help.usepylon.com/articles/7287334157-ai-plagiarism-detection)) | Web IDE | Enterprise | Employers | Bundled into hiring tests |
| **Long-tail creator verifiers, 2025–26** | HumanStamp (local, ">50% typed" email badge, [PH](https://www.hunted.space/product/humanstamp)); PoHA; TrustHuman (selfie per comment); Soulmark (speak 3 words from the post); Human Certified Publisher; "Proof of Human" Docs add-on; ByHuman (writing receipts on Arbitrum); Verify My Writing + AI-Free Cert | Mostly Chrome | Mostly free | Creators | TrustHuman 5 CWS users, Human Certified Publisher 6, HumanStamp 11 PH upvotes |
| **Authors Guild "Human Authored"** | Self-attestation plus a public registry, no process data ([AG](https://authorsguild.org/news/human-authored-certification-expands-to-all-authors/)) | Web | Free for members, $10 per title otherwise | Book authors | 6,000+ writers (secondary, [P&W](https://www.pw.org/node/1214123)) |
| **Not By AI** | Self-attested badge | Web | About $5/mo (unverified) | Creators, small businesses | Unknown |
| **World ID** | Iris scan with the Orb proves a unique person, not authorship | Mobile app | Free to users; platforms integrate | Platforms (Tinder, Zoom) | About 18M Orb-verified (vendor). Tinder "Verified Human" badge went global Apr 2026 ([The Block](https://www.theblock.co/post/397857/world-rolls-out-world-id-proof-of-human-upgrade-with-tinder-integration-zoom-feature-and-ticketing-tools)) |
| **Humanity Protocol** | Palm or palm-vein scan establishes personhood | Mobile | Token ecosystem | Web3 | "6M Human IDs" (vendor, undated) |
| **Human Passport** (ex Gitcoin Passport, Holonym) | Aggregated "stamps" into a sybil score with ZK credentials ([human.tech](https://human.tech/blog/holonym-foundation-acquires-gitcoin-passport-and-launches-human-tech)) | Web | Free | Web3 grants, airdrops | 2M+ users (vendor) |
| **C2PA / Content Credentials (Adobe CAI)** | Signed manifests. **Spec 2.3 (Jan 2026) added embedding in unstructured text** via invisible Unicode variation selectors (Annex A.7; A.8 in 2.4) ([spec 2.4](https://spec.c2pa.org/specifications/specifications/2.4/specs/C2PA_Specification.html)) | Any | Free standard | Publishers, platforms | Text tooling is third-party only (`c2patxt`, `c2pa-unstructured-text`, [docs.rs](https://docs.rs/c2pa-unstructured-text)); no major text deployment found |
| **SynthID Text** | Watermark applied when a model generates text, so it proves *AI* origin (the inverse problem). Paraphrasing and translation weaken it ([Axios](https://www.axios.com/2024/10/24/google-deepmind-ai-text-watermarking-tool)) | Gemini, open-sourced in HF Transformers | Free | Google, model providers | Deployed in Gemini; only Gemini output carries it |
| **TypingDNA** | Typing biometrics to authenticate *who* is typing, not where the content came from | Web, mobile SDK | API (B2B) | Banks, proctoring | $7M Series A in 2020 ([BuiltIn](https://www.builtinnyc.com/articles/typingdna-7m-series-a)); no newer data found |
| **Fleksy** | Keyboard SDK; announced human-vs-AI text provenance on mobile in Aug 2024 ([blog](https://fleksy.com/blog/text-provenance-mobile)) | iOS and Android keyboard SDK | B2B | Keyboard OEMs | **No shipped product found.** This is the only keyboard-native attempt I found |

I found **no shipping iOS keyboard that issues "typed by a human" proofs.**

The attack side is bigger than the creator-verifier side. On CWS, Auto Typer has 30k users, Human Auto Typer 20k, Typster 3k ("create a Revision History in Google Docs"), DocTyper 1k (requests the `debugger` permission), and GhostWriter/HumanTyper 435. That is roughly **55k users of tools built to fake Google Docs typing history**, against single-digit installs for the creator verifiers.

## 2. Attack surface

Forgery attacks, cheapest first:

1. **Paste.** Every product catches it.
2. **Software autotypers.** These are the extensions listed above, plus OS-level automation such as AutoHotkey, pyautogui, and xdotool. They add typos, pauses, and backspaces. An extension that uses the `chrome.debugger` permission can dispatch input through the DevTools protocol. My understanding is that this input arrives as trusted browser events, but I did not test it. OS-level automation is indistinguishable from real input to a content script.
3. **Hardware HID injectors** (USB Rubber Ducky-class microcontrollers) present themselves as a real keyboard, so the browser and OS see genuine keyboard input. Only timing statistics can catch them.
4. **A human retyping AI text.** No input-channel check can catch this.

The best evidence is Condrey, ["On the Insecurity of Keystroke-Based AI Authorship Detection"](https://arxiv.org/abs/2601.17280) (Jan 2026, 13,000 SBU sessions). Timing forgers that sample intervals from human distributions (histogram, statistical impersonation, LSTM) achieved **≥99.8% evasion against five classifiers**. For copy-typing, the paper proves that the mutual information between timing features and content provenance is **zero**. Composition and transcription do differ (Cohen's d = 1.28), but both clear detection thresholds by 2–4×. The same author's proposed fixes, "cognitive load correlation" ([2603.00177](https://arxiv.org/abs/2603.00177)) and ZK process attestation ([2603.00179](https://arxiv.org/abs/2603.00179)), have only analytical or simulated results and have not been tested against adaptive attackers. An LLM can also script a plausible revision trace (draft, delete, reword), which autotypers already approximate.

**The honest claim** such a product can make is limited to this: *"These characters entered this field through key events at a human-plausible pace over N minutes; X% arrived by paste, autocomplete, or AI tools that we could see; optionally, the account holder passed KYC."* That is proof of effort and of a human at the keys. It is **not** proof of who originated the content. It makes cheating more expensive: an AI-text cheater has to retype everything, roughly a 10–20× time cost. It does not make cheating impossible.

Desktop Chrome is the easiest surface to forge on. Turrii's signature also only proves that *Turrii's server* received a session, so the user has to trust Turrii's scoring, which isn't published.

## 3. Demand: where the money is

- **Education is the only proven market, and institutions pay, not students.** Turnitin sells per-student institutional licenses. GPTZero reached a claimed $30M ARR and was acquired, and that revenue is mostly detection, not process proof. Grammarly gives Authorship away free to win students and LMS integrations, with 5M+ reports. When students act on their own, it is defensive: free Authorship or Draftback replays to answer an accusation. The other student-side spend is on *attack* tools (about 55k autotyper users).
- **Hiring.** Process proof shows up as a feature inside assessment platforms (HackerRank, CoderPad), and the employer pays. Cover letters are losing weight rather than gaining verification: NHH (Aug 2026) found employers no longer trust them ([NHH](https://nhh.no/en/nhh-bulletin/article-archive/2026/august/the-cover-letter-is-on-its-way-out/)), and Tilburg found AI-written letters don't change hiring odds ([ioplus](https://ioplus.nl/en/posts/ai-improves-cover-letters-not-hiring-chances)). I found no market where candidates pay to prove a letter is human.
- **Creators and LinkedIn.** People talk about this a lot but pay little. Every process-proof product here has single- or double-digit installs (Turrii 8, TrustHuman 5, Human Certified Publisher 6). The creator scheme with real adoption, the Authors Guild's (6,000+ writers), uses **self-attestation and no telemetry**, and it is mostly free.
- **Dating.** Stated aversion to AI messages is strong. Commercial surveys report 62% of Gen Z and 70% of millennials would be put off ([Hily](https://www.globaldatinginsights.com/featured/ai-use-in-online-dating-rises-hily-report-shows/)), about 6 in 10 users believe they've hit AI-written chats (Norton 2025), and 26% of US adults have used AI for dating (Match/Kinsey). The platform is the payer for *personhood*: Tinder plus World ID, with 5 free Boosts as the incentive. Match's CEO says off-platform AI coaching is something "there's not much we can do about." **Nobody verifies message authorship.** That is an open gap, but the buyer would be a platform.
- **Journalism.** Effort goes into C2PA for media. Text embedding exists in the spec but has no deployment I could find.

**Bottom line:** money flows to institutions and platforms (B2B). Consumers will not pay to prove they're human, and Turrii's B2C creator subscription is the weakest-evidenced model in the set.

## 4. iOS keyboard as the capture surface

Sources: Apple's [Custom Keyboard guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html), [App Review 4.4.1](https://developer.apple.com/app-store/review/guidelines/), and the [App Attest docs](https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity).

**What a keyboard extension can observe:**
- Every touch on its own view: timestamp, the touch point inside the key, and touch radius. Desktop key events don't carry the last two, and they form a motor signature autotypers don't produce.
- Which words came from its own autocorrect or suggestion bar.
- `textDocumentProxy.documentContextBeforeInput` and `documentContextAfterInput` (a partial window whose size varies by app), plus `textDidChange` and `selectionDidChange`.
- By diffing the context, insertions it didn't make: paste, Apple Writing Tools rewrites, autofill, text typed while the user switched to another keyboard.
- BARkey already polls the proxy every 0.3 s to infer that a message was sent (`KeyboardViewController.swift`).

**What it cannot observe or do:**
- Secure fields and phone pads; the system keyboard takes over.
- Apps that opt out of custom keyboards (banks, HIPAA apps).
- The host app's identity, through public API.
- The whole document.
- Dictation (extensions have no microphone).
- **Hardware keyboards bypass the extension entirely.** This is common knowledge for iOS keyboards but I have not verified it on iOS 26.
- Network access and the App Group shared container without **Full Access**.
- Memory is tight. BARkey notes about 30–50 MB; Apple publishes no number.

**App Review constraints:**
- **4.4.1:** keyboards must "remain functional without full network access and without requiring full access" and may "**collect user activity only to enhance the functionality of the user's keyboard extension on the iOS device**."
- **4.4:** extensions may not include marketing, advertising, or in-app purchases.
- So proof issuance has to be framed as a keyboard function the user explicitly invokes. Capture should stay on the device and only a signed digest should leave. Purchases have to live in the containing app.
- How App Review would read "certify my typing" is untested (unverified risk). Grammarly's networked iOS keyboard is a precedent for server processing of keyboard input.

**Attestation:**
- **App Attest does not work in keyboard extensions.** Apple supports it only in Action, extensible SSO, and watchOS extensions; `generateKey` fails elsewhere.
- Workable chain: the keyboard creates a CryptoKit Secure Enclave P-256 key. The containing app passes the public key to the server inside an App Attest assertion. The server issues a short certificate. The keyboard then signs proofs offline.
- Two pieces are unverified and need a device test: whether a keyboard extension with Full Access can create and use Secure Enclave keys in a shared keychain access group, and whether DeviceCheck can be called from the extension.

**Stronger or weaker than a Chrome extension?** Stronger on the input channel, weaker on coverage and sample size.

Stronger:
- Stock iOS has no supported way for other software to synthesize touches into a third-party keyboard. There is no DevTools protocol, no AutoHotkey, and HID injectors bypass the extension, which makes their text show up as *non-keyboard insertions*.
- Touch geometry is an extra signal.
- The keyboard knows exactly which words it suggested.

Remaining attacks:
- Copy-typing, the same as everywhere.
- Jailbroken or Frida-instrumented devices. App Attest covers only the containing app.
- Accessibility input (Voice Control or Switch Control tapping keys). Whether that reaches custom keyboard keys is unverified; if it does, the timing is robotic.
- Physical tapping robots, which are expensive.

Weaker:
- It sees only part of the document.
- Apps can opt out.
- Short messages give thin statistics: a 12-word dating reply is about 60 taps.
- iOS Writing Tools and keyboard switching create gaps the keyboard can only label "unknown insertion."

## 5. Better and cheaper designs than Turrii

**A. Per-message "typed here" receipts across every app (keyboard-native).** On send, or when the user taps a ✓ key, the keyboard signs:

- a hash of the normalized text,
- a compact summary: key count, duration, % characters keyboard-typed, % taken from suggestions, % non-keyboard insertions, a coarse inter-key-interval histogram, and touch-offset entropy.

It then appends a short link or code.

- *Proves:* these characters came from taps on a genuine keyboard install at human pace.
- *Doesn't prove:* who originated the idea.
- *Cost given BARkey:* low. The capture loop, App Group, sent-detection, and the Cloud Run shortlink API already exist. New work is per-touch timing, the Secure Enclave signer, cert issuance, and a verify page, roughly 1–2 weeks.
- *Objection:* a recipient has to care enough to click, and a link in a dating message may look stranger than the AI text it vouches for.

**B. No-upload, no-server verification.** Only the hash and summary leave the device; raw keystrokes never do. The proof is a signed blob, optionally embedded as a C2PA 2.3 text manifest. Verification happens on a static page (Cloudflare static) against a published root key. This removes Turrii's liability of storing writing sessions and publishing replays.

- *Proves:* the same as A, with a better privacy story.
- *Doesn't prove:* anything a teacher can replay or audit later.
- *Cost:* small, and less ops than A.
- *Objection:* platforms strip invisible Unicode (unverified for LinkedIn and iMessage). The root of trust is still your cert issuer, and education buyers want replays.

**C. "Sounds like you AND typed by you."** BARkey's on-device style profile scores the message against the user's own 500-message baseline, and the receipt carries only a bucketed match score.

- *Proves:* consistent with this person's past voice and physically typed.
- *Cost:* moderate. The profile exists; scoring short texts reliably is the hard part.
- *Strongest objection:* **BARkey's own product is the attack.** Its exported prompt exists to make an LLM write in your voice, so AI text retyped through BARkey would pass. Stylometry on 20-word messages is also weak. Treat this as a marketing line, not a security property.

**D. Honest-provenance keyboard (Usual).** Usual's Rephrase and ✦ Expand put text into the field, and the keyboard knows exactly which spans. It can label them span by span ("you typed 80%, Usual expanded 20%"), the way Grammarly Authorship does for Docs, but in every iOS app.

- *Proves:* more than a Chrome extension can, because the AI tool and the capture surface are the same code.
- *Cost:* small on top of A.
- *Objection:* it labels only Usual's own AI. ChatGPT text pasted from elsewhere shows up as "unknown insertion," which is still useful.

**E. Sell the SDK, not the badge.** A dating or messaging platform embeds the capture in its own text field. There App Attest works, the platform sees the whole message, and the platform pays, which matches where the demand evidence points (Tinder pays World ID for personhood).

- *Proves:* the most of any option, inside one app.
- *Cost:* moderate, plus sales.
- *Objection:* a platform could build this itself, and a dating app may prefer to *sell* AI writing help, as Hinge already does with prompt coaching.

A full ZK construction (ZK-PoP) is unnecessary at this stage. Option B already gets most of the privacy benefit at about 1% of the complexity.

## Open questions

1. Does App Review accept a keyboard whose function includes issuing authorship receipts under 4.4.1's "enhance the functionality of the keyboard" rule? A TestFlight external review would be a cheap probe.
2. Can a keyboard extension with Full Access use Secure Enclave keys in a shared keychain group, and DeviceCheck? This needs a device test.
3. Do Voice Control or Switch Control taps reach custom keyboard keys, and can they be told apart?
4. Do LinkedIn, iMessage, WhatsApp, and Hinge strip Unicode variation selectors, which would decide whether C2PA text manifests or a visible link are needed?
5. Would any recipient click a receipt? The cheapest falsifier is Paul sending receipts in real threads for a week. Building is not needed for that test; a hand-made link works.
6. Turrii's actual scoring and whether it catches the CWS autotypers. That needs hands-on testing with a free account, which I did not do.
7. Is any platform (a dating app, an assessment vendor, a LinkedIn-adjacent tool) willing to pay? So far that is the only demand pattern with evidence behind it.
