#if DEBUG
import Foundation

/// Simulator-only sample messages, so every screen can be exercised without
/// typing 200 texts. Launch with `-seedDemo` (messages) or `-seedDemoOnboarded`.
enum DemoData {
    static func seedIfRequested() {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("-seedDemo") || args.contains("-seedDemoOnboarded") else { return }
        MessageStore.deleteAll()
        for message in messages { MessageStore.appendMessage(message) }
        if args.contains("-seedDemoOnboarded") {
            UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
        }
    }

    static let messages: [String] = {
        let base = [
            "yeah that works", "omw", "lol no", "running 10 late sorry", "did you see the game last night",
            "ok cool", "can you grab milk on the way home", "haha", "honestly not sure, let me check",
            "sounds good", "wait what", "ugh mondays", "thanks for dinner, that was great",
            "are we still on for saturday", "I think so? lmk", "nah I'm good", "just landed",
            "send me the link when you get a sec", "lmao", "that's wild", "lowkey want tacos tonight",
            "yep", "how'd the interview go", "proud of you", "can't make it tonight, rain check?",
            "kids are finally asleep", "brutal day", "what time does it start", "I'll be there by 7",
            "sure thing", "no rush", "haha classic", "did you book the flights yet",
            "we should do that again soon", "agreed", "good call", "hmm let me think about it",
            "on the train, will call after", "ok see you there", "love that", "ha fair",
            "just finished, heading out now", "where'd you park", "ty", "ok one sec",
            "that new place on 14th is actually good", "remind me to call the plumber tomorrow",
            "did mom call you back", "it's fine, don't worry about it", "so tired",
        ]
        var out: [String] = []
        for round in 0..<2 {
            for (i, m) in base.enumerated() { out.append(round == 0 ? m : "\(m) \(["", "tho", "again", "btw"][i % 4])".trimmingCharacters(in: .whitespaces)) }
        }
        return out
    }()
}
#endif
