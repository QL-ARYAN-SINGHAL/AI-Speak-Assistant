import Foundation
import Combine

final class VoiceAssistantViewModel: ObservableObject {
    @Published private(set) var state: ConversationState = .idle
    @Published private(set) var transcript: String = ""
    @Published private(set) var response: String = ""
    @Published private(set) var errorMessage: String = ""

    private let manager: VoiceConversationManager

    init(manager: VoiceConversationManager) {
        self.manager = manager
        manager.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.state = state
            }
        }
        manager.onTranscript = { [weak self] text in
            DispatchQueue.main.async {
                self?.transcript = text
            }
        }
        manager.onResponse = { [weak self] text in
            DispatchQueue.main.async {
                self?.response = text
            }
        }
        manager.onError = { [weak self] text in
            DispatchQueue.main.async {
                self?.errorMessage = text
            }
        }
    }

    func start() {
        manager.start()
    }

    func stop() {
        manager.stop()
    }

    func setError(_ message: String) {
        errorMessage = message
    }
}
