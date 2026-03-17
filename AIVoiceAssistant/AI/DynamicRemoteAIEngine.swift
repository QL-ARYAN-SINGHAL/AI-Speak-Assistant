import Foundation

final class DynamicRemoteAIEngine: LocalAIEngine {
    private let store: RemoteAIConfigStore
    private let fallback: LocalAIEngine
    private var cachedFingerprint: String?
    private var cachedEngine: LocalAIEngine?

    init(store: RemoteAIConfigStore, fallback: LocalAIEngine) {
        self.store = store
        self.fallback = fallback
    }

    func generateResponse(messages: [ChatMessage]) async throws -> String {
        if let config = store.currentConfig(), let engine = engineForConfig(config) {
            return try await engine.generateResponse(messages: messages)
        }
        return try await fallback.generateResponse(messages: messages)
    }

    private func engineForConfig(_ config: RemoteAIConfig) -> LocalAIEngine? {
        let fingerprint = [
            config.openaiApiKey ?? "",
            config.groqApiKey ?? "",
            config.openaiModel ?? "",
            config.groqModel ?? "",
            config.openaiEndpoint ?? "",
            config.groqEndpoint ?? ""
        ].joined(separator: "|")

        if cachedFingerprint == fingerprint, let cachedEngine = cachedEngine {
            return cachedEngine
        }

        if let engine = FailoverAIEngine(config: config) {
            cachedFingerprint = fingerprint
            cachedEngine = engine
            return engine
        }

        return nil
    }
}
