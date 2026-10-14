import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Runs the voice prompt on Apple's on-device model. Nothing leaves the phone.
enum VoiceModel {

    enum Status: Equatable {
        case ready
        case unavailable(String)
    }

    /// The on-device model has a small context window, so it gets fewer examples
    /// than the exported prompt.
    static let onDeviceExampleCount = 20

    static var status: Status {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .ready
            case .unavailable(.deviceNotEligible):
                return .unavailable("This iPhone can't run Apple Intelligence. Copy your prompt into ChatGPT or Claude instead.")
            case .unavailable(.appleIntelligenceNotEnabled):
                return .unavailable("Turn on Apple Intelligence in Settings to try your voice here.")
            case .unavailable(.modelNotReady):
                return .unavailable("Apple Intelligence is still downloading. Try again in a few minutes.")
            case .unavailable:
                return .unavailable("Apple Intelligence isn't available right now.")
            }
        }
        #endif
        return .unavailable("Trying your voice on the phone needs iOS 26 with Apple Intelligence.")
    }

    static func rewrite(_ text: String, voicePrompt: String) async throws -> String {
        try await respond(
            instructions: voicePrompt,
            to: """
            Rewrite the message below the way this person would write it. Keep the meaning \
            and any facts. Output only the rewritten message, with no quotes or commentary.

            Message:
            \(text)
            """
        )
    }

    static func reply(to incoming: String, voicePrompt: String) async throws -> String {
        try await respond(
            instructions: voicePrompt,
            to: """
            Someone just sent this person the message below. Write the reply this person \
            would most likely send. Output only the reply.

            Message:
            \(incoming)
            """
        )
    }

    /// One new message in the person's voice, on a given everyday situation.
    static func fake(about situation: String, voicePrompt: String) async throws -> String {
        try await respond(
            instructions: voicePrompt,
            to: """
            Write one text message this person might send in this situation: \(situation). \
            Do not reuse any example message. Output only the message.
            """
        )
    }

    private static func respond(instructions: String, to request: String) async throws -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: request)
            return clean(response.content)
        }
        #endif
        throw VoiceModelError.unavailable
    }

    /// Plain-language reason a generation failed.
    static func friendlyMessage(for error: Error) -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), let generationError = error as? LanguageModelSession.GenerationError {
            switch generationError {
            case .exceededContextWindowSize:
                return "Your voice prompt is too long for the on-device model. Copy it into ChatGPT or Claude instead."
            case .guardrailViolation, .refusal:
                return "Apple's model declined to write that one. Try different text."
            case .assetsUnavailable:
                return "Apple Intelligence is still getting ready. Try again in a few minutes."
            case .rateLimited, .concurrentRequests:
                return "The on-device model is busy. Try again in a moment."
            default:
                break
            }
        }
        #endif
        return "Apple Intelligence couldn't run this right now. If you just turned it on, it may still be downloading."
    }

    private static func clean(_ text: String) -> String {
        var out = text.trimmingCharacters(in: .whitespacesAndNewlines)
        for quote in ["\"", "“", "”"] where out.hasPrefix(quote) || out.hasSuffix(quote) {
            out = out.trimmingCharacters(in: CharacterSet(charactersIn: "\"“”"))
        }
        return out
    }

    enum VoiceModelError: LocalizedError {
        case unavailable
        var errorDescription: String? { "Apple Intelligence isn't available on this iPhone." }
    }
}
