import Foundation

enum RemoteAIError: LocalizedError {
    case invalidEndpoint(String)
    case httpError(status: Int, message: String?)
    case apiError(String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint(let endpoint):
            return "Invalid endpoint: \(endpoint)"
        case .httpError(let status, let message):
            if let message = message, !message.isEmpty {
                return "HTTP \(status): \(message)"
            }
            return "HTTP \(status)"
        case .apiError(let message):
            return message
        case .emptyResponse:
            return "Empty response from server"
        }
    }
}
