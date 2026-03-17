import Foundation

final class FailoverAIEngine: LocalAIEngine {
    private let primary: LocalAIEngine
    private let fallback: LocalAIEngine?

    init(primary: LocalAIEngine, fallback: LocalAIEngine?) {
        self.primary = primary
        self.fallback = fallback
    }

    convenience init?(config: RemoteAIConfig) {
        let openaiKey = (config.openaiApiKey ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let groqKey = (config.groqApiKey ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        let openaiEndpoint = (config.openaiEndpoint ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let openaiEngine: LocalAIEngine? = openaiKey.isEmpty ? nil : OpenAIRemoteAIEngine(
            apiKey: openaiKey,
            model: config.openaiModel ?? "gpt-4o-mini",
            endpoint: openaiEndpoint.isEmpty ? nil : URL(string: openaiEndpoint)
        )

        let groqEndpoint = (config.groqEndpoint ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let groqEngine: LocalAIEngine? = groqKey.isEmpty ? nil : GroqRemoteAIEngine(
            apiKey: groqKey,
            model: config.groqModel ?? "llama-3.1-8b-instant",
            endpoint: groqEndpoint.isEmpty ? nil : groqEndpoint
        )

        if let openaiEngine = openaiEngine {
            self.init(primary: openaiEngine, fallback: groqEngine)
            return
        }
        if let groqEngine = groqEngine {
            self.init(primary: groqEngine, fallback: nil)
            return
        }
        return nil
    }

    func generateResponse(messages: [ChatMessage]) async throws -> String {
        do {
            return try await primary.generateResponse(messages: messages)
        } catch {
            if let fallback = fallback {
                return try await fallback.generateResponse(messages: messages)
            }
            throw error
        }
    }
}
