---
topic: "Proof of human writing: what to build, for whom, and where's the money"
date: "2026-10-14"
crew: [achen, benthomp, pg]
mode: "autonomous"
project: "barkey"
status: "captured"
---

# Jam: proof of human writing — what to build and where's the money

> **Crew:** Andrew Chen (achen), Ben Thompson (benthomp), Paul Graham (pg) · **2026-10-14** · autonomous
> **Framing:** Trigger was Turrii (turrii.com, ex not-slop.com, by Verifiably Human / github.com/Verhum): a Chrome extension that records keystrokes while you write LinkedIn/Substack posts, scores them on a server, and issues a "Verified Human" proof page; $2.99–5.99/mo; ~8 installs. Brief: `_factory/brain/research/proof-of-human-writing/LANDSCAPE.md`. Question: is a keyboard-native version built on BARkey's capture layer worth doing, and what's the efficient version?

## Synthesis

**Convergence (all three):** the writer is the wrong buyer. Every real dollar in the landscape comes from whoever *checks* (schools via Grammarly/Turnitin, employers via assessment platforms, Tinder via World ID). Turrii's 8 installs are the predicted result of selling a signal to the side that doesn't read it. All three also call out that BARkey's own "write like me" export is the attack on any proof-of-typing claim.

**Shared falsifier (all three, independently):** before building anything, Paul hand-sends ~20–50 "typed by me" receipt links in real threads for one week. Fewer than ~3 clicks and no "what is this?" kills the writer-side idea.

**Dissents:**
- *Where money could be:* achen → requester-initiated receipts ("reply with a receipt" links sent by recruiters/teachers, the Calendly loop) plus an SDK for one platform. benthomp → only an SDK sold to a dating-app *challenger* (Feeld, Raya, Bumble BFF) that controls its own display. pg → there's no first user who wants it badly; finish BARkey and sell the $9.99 export instead.
- *Whether to build at all:* pg says no; achen says only if a verifier blinks first; benthomp says only as a free feature or a platform SDK.

**Orthogonal move:** benthomp's "only the tool that inserts the AI text knows exactly which text it inserted" → provenance belongs as a free honesty label inside Usual (you typed 80%, Usual expanded 20%), not as a product. achen and pg both landed on the same Usual feature.

**Lands the goal vs. builds the company:** the goal (a better Turrii) is cheap to beat and not worth winning. The company, if there is one, is a platform SDK, and it only exists if a dating or assessment platform signs a pilot.

**One line:** Don't sell a "human" badge to writers; finish BARkey, give provenance away as Usual's honesty label, and only build an SDK if a platform asks for it.

## The takes

### Andrew Chen — this is a signaling network, and nobody's building the reader side

The way I think about it, a proof-of-human badge is a trust signal. A trust signal is a network good, so its value comes almost entirely from how many readers recognize it and act on it. A blue check nobody checks is just decoration. Turrii's 8 Chrome installs don't show a weak capture surface. They show a team building a single-player tool for the writer and hoping a network shows up on the reader side. That's backwards.

**Hard side vs. easy side.** Writers are the easy side. Lots of people would like a "human" sticker if it cost nothing. The hard side is the verifier, the person who has to care enough to click, and who in the best case requires it. Every bit of real traction in Paul's landscape doc comes from verifiers: an instructor asks for the Grammarly Authorship report (5M+ reports), employers bundle replay into HackerRank, Tinder pays World ID. No writer anywhere is paying to prove anything without being asked. At Uber we didn't start a city by buying riders. We guaranteed drivers' hourly earnings, because supply brought demand with it. Here the supply is verifiers who demand proof, and nobody in this category is recruiting them.

**Does the receipt link spread itself?** Mostly no, and here's the arithmetic. It's the Hotmail "PS: get free email" loop, except Hotmail's footer pointed to a free web signup. Yours points to an iOS keyboard that needs Full Access and a 4-step setup. Rough guesses: Paul sends 50 receipts a week, 2% get clicked (the law of shitty clickthroughs applies to novel links too, and in a Hinge thread the link looks stranger than the AI text it vouches for), and 5% of clickers install a keyboard. That's K ≈ 0.05 per user per week. The loop is dead before it starts. The keyboard's biggest security advantage, input you can't easily fake, is also its biggest distribution liability.

**The BARkey contradiction.** BARkey is built on "succeeds when you delete it." That's a designed-in tragic curve: retention trends to zero on purpose. A proof product needs a keyboard that stays installed forever. And as the doc admits, BARkey's own export is the attack: a write-like-me prompt plus retyping passes the check. These two products shouldn't share a brand. The capture code can be shared, but the identities can't.

**What I'd actually build:**

1. **Requester-initiated receipts (the Calendly loop).** Calendly spreads because the sender imposes it on the recipient. Flip Turrii: a recruiter, teacher or editor sends a "reply with a typed-here receipt" link. The demand comes from the hard side, and every request is an install prompt carrying the asker's authority behind it.
2. **Provenance as a free feature of a keyboard people keep for other reasons (Usual, option D).** Come for the tool, stay for the network. Span labels like "you typed 80%, Usual expanded 20%" cost little on top of a keyboard with real daily use. A standalone badge keyboard has no reason to be retained.
3. **Money comes from the SDK (option E), not subscriptions.** Pick one dating app or one assessment vendor. That's your atomic network: one platform where every message in a thread can carry the signal, the full text field is visible, and App Attest works.

**Falsifiers, cheapest first:**
- **Week 1:** Paul hand-sends 50 receipt links in real threads. Fewer than 5 clicks and zero "wait, what is this?" replies kills the writer-side loop. No build needed.
- **Week 2:** Recruit one hard-side verifier: a teacher or hiring manager who requires receipts on 20 submissions. If not one of them will make it mandatory, there's no network, only a feature.
- **Weeks 3–4:** Pitch the SDK to 3 dating or assessment platforms. No LOI or paid pilot means it's a nice open-source library, not a company.

**Stage diagnostic:** pre-cold-start. Turrii isn't a competitor. It's a free data point showing writer-side pull is roughly zero. I've been wrong before about consumer tools turning into networks just because they're delightful (Clubhouse taught me plenty). That's exactly why I'd want the verifier to blink first before Paul spends a week on Secure Enclave certificates.

**ONE-LINE VERDICT:** A badge nobody's asked for doesn't make a network, so build the verifier's "prove it" link first and let the keyboard ride in behind it, or don't build it at all.

### Ben Thompson — certification is the hollow middle of a Smiling Curve

The structural problem with "proof of human writing" shows up when you lay out the value chain. It has three layers.

1. **Capture**: where the keystrokes happen. Apple owns the iOS input layer. Superhuman (Grammarly plus GPTZero) owns the document layer in education, distributed through the LMS.
2. **Certification**: scoring the session and signing the proof. This is where Turrii sits.
3. **Display**: where a reader actually sees the proof. LinkedIn, Substack, Tinder and Hinge own this. They aggregate the readers, so they decide which signals count.

To use my own terminology, this is a Smiling Curve. Value collects at the two ends, the input surface and the aggregator that owns the reader's attention. The middle, which is certification, gets hollowed out. Turrii sits exactly in that middle. It sells a signal to the supply side (creators) that the demand side never sees. Eight users is not an execution failure. It is what you would predict from where Turrii sits.

The history matters here. Twitter's blue check meant something because Twitter showed it next to every tweet. A Turrii badge means nothing because LinkedIn doesn't render it. Credentials get their value from whoever controls the display, and that is the aggregator, never the issuer. World ID understood this. It didn't ask people to pay to prove they're human. It sold to Tinder, and Tinder put the badge where readers look. The payer is the platform, every time.

Now, the keyboard. The research is right that the iOS keyboard is a stronger capture surface than Chrome: there's no DevTools injection, you get touch geometry, and the keyboard knows which words it suggested. But a stronger input channel doesn't change where you sit on the curve. You still have no display. On top of that, you'd be asking people to replace the most-used software on their phone and grant Full Access, all to get a badge nobody reads.

There is also a contradiction particular to BARkey. BARkey exists to make an LLM write in your voice. A product that also claims to prove you wrote something is selling the attack and the defense in one SKU. And the Condrey paper settles the technical question: timing data carries zero information about whether a person composed text or copy-typed it. What you can certify is effort, not authorship.

Where does that leave you? There is one integration point where real value exists, and Superhuman already found it. **Only the tool that inserts the AI text knows exactly which text it inserted.** Grammarly Authorship works because Grammarly is both the assistant and the recorder. It gives Authorship away free because disclosure is the complement to selling AI writing. Make the complement free and the core product gets more valuable.

1. **Do not build Turrii for iOS.** A consumer subscription for proof of humanity has negative evidence, and there is no display layer to take advantage of.
2. **Ship provenance as a free feature of Usual's keyboard, not as a product.** Usual's AI features label their own text span by span: "you typed 80%, Usual expanded 20%." The pitch is "the AI keyboard that's honest about itself." Kill condition: Paul sends hand-made receipt links in real threads for one week. If fewer than 3 of roughly 30 recipients open one, drop even the feature.
3. **The only business is selling to an aggregator's challengers.** Tinder has World ID. Challengers that can't win on scale have to win on trust, and Feeld, Raya and Bumble's BFF are the candidates. Offer a "message typed on-device" SDK for their own text field. Inside their app, App Attest works and they see the whole message. Send 3 pitches. Kill condition: no paid pilot or LOI within 45 days. Expect Hinge to say no, because Hinge sells AI writing coaching itself.

Option 3 is the only one where the buyer controls the display. If nobody bites, the market has answered, and it is the same answer it gave Turrii.

**ONE-LINE VERDICT:** Proof of human is worth whatever the platform that displays it says it's worth, so sell to a dating-app challenger or give it away as the AI keyboard's honesty label, and never sell the badge to the writer.

### Paul Graham — the people who want this aren't the people who'd have to install it

Start with the question I always ask first. Why did you build this? Paul didn't build BARkey to prove he's human. He built it so an LLM could pass as him. Then a guy with 8 users made a Chrome extension, and now the question is whether to turn the same keyboard around and point it the other way. That isn't a problem you ran into. It's a reaction to a competitor. And the competitor is losing.

Look at the numbers in your own landscape doc, because they settle most of this. Process-proof products for creators have 8, 5 and 6 users. Tools built to *fake* human typing have about 55,000. When something surprises you, treat it as a clue. The clue here is that demand runs about 7,000 to 1 in the other direction. People don't want to prove they wrote it. They want to get away with not writing it. 26% of US adults have used AI for dating. That's the want. BARkey is already on that side. Proof-of-human is a sitting-around-the-table idea: everyone nods that AI slop is bad, and then nobody installs anything.

Here's the structural problem, and I don't think better engineering fixes it. Proof of human writing is wanted by the *reader*, but the *writer* has to install it. A woman on Hinge wonders if this guy is using ChatGPT. She can't make him use your keyboard. And the guy most willing to install a "verified human" keyboard is the one who least needs it. The only writer who wants proof badly is the accused one: a student facing an AI-cheating charge. That's real pain. But he wrote the essay on a laptop in Google Docs, and Grammarly gives him a replay for free. A phone keyboard is the wrong surface for the one user who's desperate.

So who's the first user who wants this badly? I can't name one, and you can't either. That's the answer.

The schlep argument doesn't save it. Secure Enclave keys from an extension, App Review under 4.4.1, a cert issuer. That's a real schlep, and schleps are good when someone is waiting on the other side of the wall. Nobody is. And the research doc says the quiet part itself: a human retyping AI text passes every check, and "BARkey's own product is the attack." You'd be selling a lock alongside the lockpick.

What I'd actually do, all of it falsifiable:

1. **Don't build it. Hand-make it.** For one week, Paul adds a hand-made "typed by me" link to 20 real messages (texts, LinkedIn, a dating thread if he has one). The link goes to a static page. Kill the idea if fewer than 3 people click, or if nobody asks "what is this?" unprompted. Cost: an afternoon.
2. **Find 10 accused students and talk to them.** Ask one question: would a phone receipt have helped? I predict 10 of 10 say no, because the essay was in Docs. If 3 say yes, I'm wrong, and the market is the accused, not creators.
3. **Finish BARkey first.** The context file says the next step is "wire StoreKit," and it's been saying that since March 15. That's seven months. Starting a new product on top of an unfinished one is how founders avoid finding out whether the first one works. Put the $9.99 export live. If 50 strangers pay, you've learned which side of this market is real.
4. **If you must ship provenance, make it a free feature, not a company.** Put a ✓ key in the Usual keyboard: "you typed 80%, Usual expanded 20%." No server, no subscription, a static verify page. It's one week of work. It works as a reason to talk about the keyboard, not as revenue. It does beat Turrii on everything Turrii charges for, which shows how little Turrii is charging for.

The only money in this space comes from institutions and platforms. And Hinge would rather sell AI writing help than verify its absence.

**ONE-LINE VERDICT:** The demand is 7,000-to-1 for faking human writing, not proving it. Paul already built the side people want, so finish BARkey and let Turrii keep its 8 users.
