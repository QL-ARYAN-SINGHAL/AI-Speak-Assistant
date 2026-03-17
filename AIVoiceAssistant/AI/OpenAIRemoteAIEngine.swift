import Foundation

final class OpenAIRemoteAIEngine: LocalAIEngine {
    private let apiKey: String
    private let model: String
    private let endpoint: URL

    init(apiKey: String, model: String = "gpt-4o-mini", endpoint: URL? = nil) {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = endpoint ?? URL(string: "https://api.openai.com/v1/chat/completions")!
    }

    func generateResponse(messages: [ChatMessage]) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = OpenAIChatRequest(
            model: model,
            messages: messages.map { .init(role: $0.role.rawValue, content: $0.content) }
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw OpenAIError.httpError(status: http.statusCode, body: bodyText)
        }

        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw OpenAIError.missingContent
        }
        return content
    }
}

private struct OpenAIChatRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }
    let model: String
    let messages: [Message]
}

private struct OpenAIChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

enum OpenAIError: LocalizedError {
    case invalidResponse
    case httpError(status: Int, body: String)
    case missingContent

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from OpenAI."
        case .httpError(let status, let body):
            return "OpenAI HTTP \(status): \(body)"
        case .missingContent:
            return "OpenAI response missing content."
        }
    }
}
