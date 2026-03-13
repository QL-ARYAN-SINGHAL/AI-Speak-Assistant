import Foundation

enum ChatRole: String {
    case system
    case user
    case assistant
}

struct ChatMessage {
    let role: ChatRole
    let content: String
}
