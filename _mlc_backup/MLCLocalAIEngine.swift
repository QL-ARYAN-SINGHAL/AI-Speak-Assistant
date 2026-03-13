import Foundation
import MLCSwift

final class MLCLocalAIEngine: LocalAIEngine {
    private let engine = MLCEngine()
    private let config: MLCModelConfig
    private var loaded = false

    init?(config: MLCModelConfig? = MLCModelConfig.loadFromBundle()) {
        guard let config = config else { return nil }
        self.config = config
        guard Self.hasBundledModel(at: config.modelPath) else {
            print("[MLC] Missing bundled model at path: \(config.modelPath)")
            return nil
        }
    }

    func generateResponse(messages inputMessages: [ChatMessage]) async throws -> String {
        try await loadIfNeeded()

        var messages: [ChatCompletionMessage] = []
        for msg in inputMessages {
            let role: ChatCompletionMessageRole
            switch msg.role {
            case .system: role = .system
            case .user: role = .user
            case .assistant: role = .assistant
            }
            messages.append(ChatCompletionMessage(role: role, content: msg.content))
        }

        var output = ""
        let stream = await engine.chat.completions.create(messages: messages)
        for await res in stream {
            if let delta = res.choices.first?.delta.content?.asText() {
                output += delta
            }
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func loadIfNeeded() async throws {
        if loaded { return }
        let modelPath = resolveModelPath(config.modelPath)
        print("[MLC] Loading model from: \(modelPath)")
        print("[MLC] Model lib: \(config.modelLib)")
        await engine.reload(modelPath: modelPath, modelLib: config.modelLib)
        loaded = true
        print("[MLC] Model loaded")
    }

    private func resolveModelPath(_ path: String) -> String {
        if path.hasPrefix("/") { return path }
        if let bundlePath = Bundle.main.path(forResource: path, ofType: nil) {
            return bundlePath
        }
        return path
    }

    private static func hasBundledModel(at path: String) -> Bool {
        let resolvedPath: String
        if path.hasPrefix("/") {
            resolvedPath = path
        } else if let bundlePath = Bundle.main.path(forResource: path, ofType: nil) {
            resolvedPath = bundlePath
        } else {
            return false
        }
        let configPath = (resolvedPath as NSString).appendingPathComponent("mlc-app-config.json")
        return FileManager.default.fileExists(atPath: configPath)
    }
}
