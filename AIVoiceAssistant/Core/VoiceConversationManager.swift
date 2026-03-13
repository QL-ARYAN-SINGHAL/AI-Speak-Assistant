import Foundation

final class VoiceConversationManager {
    private let stateMachine = ConversationStateMachine()
    private let recognizer = SpeechRecognizerManager()
    private let player = SpeechPlaybackManager()
    private let llmService: LLMService
    private var currentTask: Task<Void, Never>?
    private var endOfSpeechWorkItem: DispatchWorkItem?
    private let endOfSpeechDelay: TimeInterval = 1.2
    private var isRecognizerRunning = false
    private var suppressTranscriptionUntil = Date.distantPast
    private var bargeInArmedAt = Date.distantPast
    private var bargeInDetectionCount = 0
    private var lastBargeInDetectionAt = Date.distantPast

    var onStateChange: ((ConversationState) -> Void)?
    var onTranscript: ((String) -> Void)?
    var onResponse: ((String) -> Void)?
    var onError: ((String) -> Void)?

    private var lastPartial = ""

    init(llmService: LLMService) {
        self.llmService = llmService
        stateMachine.onChange = { [weak self] state in
            self?.onStateChange?(state)
        }

        recognizer.onPartial = { [weak self] text in
            self?.handlePartial(text)
        }
        recognizer.onFinal = { [weak self] text in
            self?.handleFinal(text)
        }
        recognizer.onSpeechDetected = { [weak self] in
            self?.handleSpeechDetected()
        }

        player.onStart = { [weak self] in
            self?.handleSpeechPlaybackStarted()
        }
        player.onFinish = { [weak self] in
            self?.handleSpeechPlaybackFinished()
        }
    }

    func start() {
        do {
            try AudioSessionManager.shared.configureForVoiceChat()
            print("[Conversation] Audio session configured")
        } catch {
            print("[Conversation] Audio session error: \(error.localizedDescription)")
            onError?("Audio session error: \(error.localizedDescription)")
            return
        }

        recognizer.requestAuthorization { [weak self] granted in
            guard let self = self else { return }
            print("[Conversation] Speech auth granted: \(granted)")
            if !granted {
                self.onError?("Speech recognition not authorized")
                return
            }
            self.startRecognizerIfNeeded()
            self.transition(.listening)
        }
    }

    func stop() {
        stopRecognizer()
        player.stop()
        transition(.idle)
    }

    private func handlePartial(_ text: String) {
        if stateMachine.state == .speaking {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count >= 2 {
                handleBargeIn()
            }
            return
        }
        guard stateMachine.state == .listening else { return }
        guard Date() >= suppressTranscriptionUntil else { return }
        lastPartial = text
        onTranscript?(text)
        print("[Conversation] Partial transcript: \(text)")
        scheduleEndOfSpeech(using: text)
    }

    private func handleFinal(_ text: String) {
        if stateMachine.state == .speaking {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count >= 2 {
                handleBargeIn()
            }
            return
        }
        guard stateMachine.state == .listening else { return }
        guard Date() >= suppressTranscriptionUntil else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        print("[Conversation] Final transcript: \(trimmed)")
        guard !trimmed.isEmpty else { return }
        cancelEndOfSpeech()
        stopRecognizer()
        recognizer.setTranscriptionEnabled(true)
        recognizer.setAutoRestartEnabled(true)

        transition(.processing)
        currentTask?.cancel()
        currentTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                print("[Conversation] Sending to LLM")
                let response = try await self.llmService.generateResponse(userText: trimmed)
                if Task.isCancelled { return }
                print("[Conversation] LLM response: \(response)")
                self.onResponse?(response)
                DispatchQueue.main.async { [weak self] in
                    self?.player.speak(response)
                }
            } catch {
                if Task.isCancelled { return }
                print("[Conversation] LLM error: \(error.localizedDescription)")
                self.onError?("AI error: \(error.localizedDescription)")
                self.transition(.listening)
                self.startRecognizerIfNeeded()
            }
        }
    }

    private func handleSpeechDetected() {
        let now = Date()
        if stateMachine.state == .speaking {
            // Allow barge-in after a short delay to avoid TTS echo triggering it.
            if now < bargeInArmedAt { return }
            if now.timeIntervalSince(lastBargeInDetectionAt) > 1 {
                bargeInDetectionCount = 0
            }
            bargeInDetectionCount += 1
            lastBargeInDetectionAt = now
            if bargeInDetectionCount >= 2 {
                handleBargeIn()
            }
            return
        }
        guard stateMachine.state == .listening else { return }
        guard now >= suppressTranscriptionUntil else { return }
        print("[Conversation] Speech detected event")
    }

    private func handleSpeechPlaybackStarted() {
        cancelEndOfSpeech()
        startRecognizerIfNeeded()
        recognizer.setTranscriptionEnabled(false)
        recognizer.setAutoRestartEnabled(false)
        bargeInDetectionCount = 0
        lastBargeInDetectionAt = Date.distantPast
        bargeInArmedAt = Date().addingTimeInterval(0.2)
        transition(.speaking)
    }

    private func handleSpeechPlaybackFinished() {
        transition(.listening)
        // Cooldown to prevent the recognizer from capturing the tail of TTS output.
        suppressTranscriptionUntil = Date().addingTimeInterval(0.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.recognizer.setTranscriptionEnabled(true)
            self?.recognizer.setAutoRestartEnabled(true)
            self?.startRecognizerIfNeeded()
        }
    }

    private func handleBargeIn() {
        print("[Conversation] Barge-in")
        cancelEndOfSpeech()
        currentTask?.cancel()
        player.stop()
        transition(.interrupted)
        transition(.listening)
        recognizer.setTranscriptionEnabled(true)
        recognizer.setAutoRestartEnabled(true)
        startRecognizerIfNeeded()
    }

    private func transition(_ state: ConversationState) {
        print("[Conversation] State -> \(state.rawValue)")
        stateMachine.transition(to: state)
    }

    private func scheduleEndOfSpeech(using text: String) {
        cancelEndOfSpeech()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.stateMachine.state != .listening { return }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return }
            if trimmed.count < 2 { return }
            print("[Conversation] End-of-speech timeout; using partial as final")
            self.handleFinal(trimmed)
        }
        endOfSpeechWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + endOfSpeechDelay, execute: workItem)
    }

    private func cancelEndOfSpeech() {
        endOfSpeechWorkItem?.cancel()
        endOfSpeechWorkItem = nil
    }

    private func startRecognizerIfNeeded() {
        guard !isRecognizerRunning else { return }
        do {
            try recognizer.start()
            isRecognizerRunning = true
            print("[Conversation] Recognizer started")
        } catch {
            print("[Conversation] Recognizer start error: \(error.localizedDescription)")
            onError?("Speech recognizer error: \(error.localizedDescription)")
        }
    }

    private func stopRecognizer() {
        guard isRecognizerRunning else { return }
        recognizer.stop()
        isRecognizerRunning = false
    }
}
