import Foundation

protocol LLMService {
    func generateResponse(userText: String) async throws -> String
    func reset()
}

final class DefaultLLMService: LLMService {
    private let engine: LocalAIEngine
    private var messages: [ChatMessage]
    private let maxHistoryPairs: Int

    init(engine: LocalAIEngine, systemPrompt: String, maxHistoryPairs: Int = 6) {
        self.engine = engine
        self.maxHistoryPairs = maxHistoryPairs
        self.messages = [ChatMessage(role: .system, content: systemPrompt)]
    }

    func generateResponse(userText: String) async throws -> String {
        messages.append(ChatMessage(role: .user, content: userText))
        trimHistoryIfNeeded()
        let response = try await engine.generateResponse(messages: messages)
        messages.append(ChatMessage(role: .assistant, content: response))
        trimHistoryIfNeeded()
        return response
    }

    func reset() {
        if let system = messages.first(where: { $0.role == .system }) {
            messages = [system]
        } else {
            messages.removeAll()
        }
    }

    private func trimHistoryIfNeeded() {
        // Keep the system prompt + last N user/assistant pairs.
        let system = messages.first(where: { $0.role == .system })
        let nonSystem = messages.filter { $0.role != .system }
        let maxNonSystem = maxHistoryPairs * 2
        let trimmedNonSystem = Array(nonSystem.suffix(maxNonSystem))
        if let system = system {
            messages = [system] + trimmedNonSystem
        } else {
            messages = trimmedNonSystem
        }
    }
}
