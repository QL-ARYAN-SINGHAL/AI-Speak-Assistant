import Foundation

protocol LocalAIEngine {
    func generateResponse(messages: [ChatMessage]) async throws -> String
}

final class SimpleLocalAIEngine: LocalAIEngine {
    func generateResponse(messages: [ChatMessage]) async throws -> String {
        let lastUser = messages.last(where: { $0.role == .user })?.content ?? ""
        let trimmed = lastUser.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "I did not catch that. Can you say it again?" }
        if trimmed.lowercased().contains("hello") { return "Hello. How can I help you today?" }
        return "You said: \(trimmed). What would you like to do next?"
    }
}
