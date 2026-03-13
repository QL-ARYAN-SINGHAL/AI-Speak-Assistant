import Foundation

final class GeminiRemoteAIEngine: LocalAIEngine {
    private let apiKey: String
    private let model: String
    private let endpoint: String

    init(apiKey: String, model: String = "gemini-2.0-flash", endpoint: String? = nil) {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = endpoint ?? "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
    }

    func generateResponse(messages: [ChatMessage]) async throws -> String {
        let contents = buildContents(from: messages)
        let body = GeminiGenerateContentRequest(contents: contents)
        let requestData = try JSONEncoder().encode(body)

        guard let url = URL(string: endpoint) else {
            throw RemoteAIError.invalidEndpoint(endpoint)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = requestData

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if !(200...299).contains(status) {
            let message = GeminiGenerateContentResponse.parseErrorMessage(from: data)
            throw RemoteAIError.httpError(status: status, message: message)
        }

        let decoded = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: data)
        if let text = decoded.firstText {
            return text
        }
        if let errorMessage = decoded.error?.message {
            throw RemoteAIError.apiError(errorMessage)
        }
        throw RemoteAIError.emptyResponse
    }

    private func buildContents(from messages: [ChatMessage]) -> [GeminiGenerateContentRequest.Content] {
        var systemPrefix: String?
        var result: [GeminiGenerateContentRequest.Content] = []
        for msg in messages {
            switch msg.role {
            case .system:
                systemPrefix = msg.content
            case .user:
                result.append(GeminiGenerateContentRequest.Content(role: "user", parts: [.init(text: msg.content)]))
            case .assistant:
                result.append(GeminiGenerateContentRequest.Content(role: "model", parts: [.init(text: msg.content)]))
            }
        }

        if let systemPrefix = systemPrefix?.trimmingCharacters(in: .whitespacesAndNewlines), !systemPrefix.isEmpty {
            if result.isEmpty {
                result = [GeminiGenerateContentRequest.Content(role: "user", parts: [.init(text: systemPrefix)])]
            } else if result[0].role == "user" {
                let combined = systemPrefix + "\n\n" + (result[0].parts.first?.text ?? "")
                result[0] = GeminiGenerateContentRequest.Content(role: "user", parts: [.init(text: combined)])
            } else {
                result.insert(GeminiGenerateContentRequest.Content(role: "user", parts: [.init(text: systemPrefix)]), at: 0)
            }
        }

        return result
    }
}

struct GeminiGenerateContentRequest: Encodable {
    struct Content: Encodable {
        let role: String
        let parts: [Part]
    }

    struct Part: Encodable {
        let text: String
    }

    let contents: [Content]
}

struct GeminiGenerateContentResponse: Decodable {
    struct Candidate: Decodable {
        let content: Content?
    }

    struct Content: Decodable {
        let parts: [Part]?
    }

    struct Part: Decodable {
        let text: String?
    }

    struct APIError: Decodable {
        let message: String?
    }

    let candidates: [Candidate]?
    let error: APIError?

    var firstText: String? {
        return candidates?.first?.content?.parts?.compactMap { $0.text }.joined()
    }

    static func parseErrorMessage(from data: Data) -> String? {
        return try? JSONDecoder().decode(GeminiGenerateContentResponse.self, from: data).error?.message
    }
}
