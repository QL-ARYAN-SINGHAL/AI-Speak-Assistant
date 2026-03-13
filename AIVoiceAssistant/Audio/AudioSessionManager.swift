import AVFoundation

final class AudioSessionManager {
    static let shared = AudioSessionManager()

    private init() {}

    func configureForVoiceChat() throws {
        let session = AVAudioSession.sharedInstance()
        // VoiceChat mode enables system echo cancellation on iOS.
        try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setPreferredSampleRate(48000)
        try session.setPreferredIOBufferDuration(0.01)
        try session.setActive(true, options: [])
    }
}
