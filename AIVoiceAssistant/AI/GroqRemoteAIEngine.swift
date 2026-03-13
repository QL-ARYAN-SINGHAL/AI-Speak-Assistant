import Foundation

final class GroqRemoteAIEngine: LocalAIEngine {
    private let apiKey: String
    private let model: String
    private let endpoint: String

    init(apiKey: String, model: String = "llama-3.1-8b-instant", endpoint: String? = nil) {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = endpoint ?? "https://api.groq.com/openai/v1/chat/completions"
    }

    func generateResponse(messages: [ChatMessage]) async throws -> String {
        let body = GroqChatRequest(
            model: model,
            messages: messages.map { GroqChatRequest.Message(role: $0.role.rawValue, content: $0.content) }
        )
        let requestData = try JSONEncoder().encode(body)

        guard let url = URL(string: endpoint) else {
            throw RemoteAIError.invalidEndpoint(endpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = requestData

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if !(200...299).contains(status) {
            let message = GroqChatResponse.parseErrorMessage(from: data)
            throw RemoteAIError.httpError(status: status, message: message)
        }

        let decoded = try JSONDecoder().decode(GroqChatResponse.self, from: data)
        if let text = decoded.firstText {
            return text
        }
        if let errorMessage = decoded.error?.message {
            throw RemoteAIError.apiError(errorMessage)
        }
        throw RemoteAIError.emptyResponse
    }
}

struct GroqChatRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [Message]
}

struct GroqChatResponse: Decodable {
    struct Choice: Decodable {
        let message: Message?
    }

    struct Message: Decodable {
        let content: String?
    }

    struct APIError: Decodable {
        let message: String?
    }

    let choices: [Choice]?
    let error: APIError?

    var firstText: String? {
        return choices?.first?.message?.content
    }

    static func parseErrorMessage(from data: Data) -> String? {
        return try? JSONDecoder().decode(GroqChatResponse.self, from: data).error?.message
    }
}
