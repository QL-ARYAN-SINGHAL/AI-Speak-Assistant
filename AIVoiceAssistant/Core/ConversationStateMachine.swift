import Foundation

final class ConversationStateMachine {
    private(set) var state: ConversationState = .idle
    var onChange: ((ConversationState) -> Void)?

    func transition(to next: ConversationState) {
        guard state != next else { return }
        state = next
        onChange?(next)
    }
}
