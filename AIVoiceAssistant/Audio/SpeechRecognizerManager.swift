import AVFoundation
import Speech

final class SpeechRecognizerManager {
    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private var speechFramesRemaining = 0
    private var isTranscriptionEnabled = true
    private var isAutoRestartEnabled = true

    var onPartial: ((String) -> Void)?
    var onFinal: ((String) -> Void)?
    var onSpeechDetected: (() -> Void)?

    var supportsOnDeviceRecognition: Bool {
        return recognizer?.supportsOnDeviceRecognition ?? false
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                print("[SpeechRecognizer] Authorization status: \(status.rawValue)")
                completion(status == .authorized)
            }
        }
    }

    func start() throws {
        stop()

        if !supportsOnDeviceRecognition {
            print("[SpeechRecognizer] On-device recognition not available; falling back to server-based recognition")
        }

        print("[SpeechRecognizer] Starting audio engine + recognition")
        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true
        request?.requiresOnDeviceRecognition = supportsOnDeviceRecognition
        request?.taskHint = .dictation

        guard let request = request else { return }

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                if result.isFinal {
                    print("[SpeechRecognizer] Final: \(result.bestTranscription.formattedString)")
                    self.onFinal?(result.bestTranscription.formattedString)
                } else {
                    print("[SpeechRecognizer] Partial: \(result.bestTranscription.formattedString)")
                    self.onPartial?(result.bestTranscription.formattedString)
                }
            }
            if let error = error {
                print("[SpeechRecognizer] Error: \(error.localizedDescription)")
                // Avoid restart loops when transcription is disabled.
                if self.isAutoRestartEnabled && self.isTranscriptionEnabled {
                    // Restart on errors to keep mic persistent.
                    self.restartIfNeeded()
                }
            }
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.detectSpeech(buffer: buffer)
            if self.isTranscriptionEnabled {
                self.request?.append(buffer)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        print("[SpeechRecognizer] Audio engine started")
    }

    func stop() {
        print("[SpeechRecognizer] Stopping")
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        request?.endAudio()
        request = nil
        task?.cancel()
        task = nil
    }

    func setTranscriptionEnabled(_ enabled: Bool) {
        isTranscriptionEnabled = enabled
    }

    func setAutoRestartEnabled(_ enabled: Bool) {
        isAutoRestartEnabled = enabled
    }

    private func detectSpeech(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let count = Int(buffer.frameLength)
        if count == 0 { return }
        var sum: Float = 0
        let data = channelData[0]
        for i in 0..<count {
            let v = data[i]
            sum += v * v
        }
        let rms = sqrt(sum / Float(count))

        if rms >= 0.03 {
            speechFramesRemaining = 3
            print("[SpeechRecognizer] Speech detected (rms=\(rms))")
            onSpeechDetected?()
        } else if speechFramesRemaining > 0 {
            speechFramesRemaining -= 1
            onSpeechDetected?()
        }
    }

    private func restartIfNeeded() {
        do {
            try start()
        } catch {
            print("[SpeechRecognizer] Restart failed: \(error.localizedDescription)")
        }
    }
}
