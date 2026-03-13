import Foundation

struct RemoteAIConfig: Decodable {
    let geminiApiKey: String?
    let groqApiKey: String?
    let geminiModel: String?
    let groqModel: String?
    let geminiEndpoint: String?
    let groqEndpoint: String?
    let systemPrompt: String?

    var hasGeminiKey: Bool {
        let key = (geminiApiKey ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty
    }

    var hasGroqKey: Bool {
        let key = (groqApiKey ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty
    }

    static func loadFromBundle() -> RemoteAIConfig? {
        guard let url = Bundle.main.url(forResource: "RemoteAIConfig", withExtension: "json") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(RemoteAIConfig.self, from: data)
        } catch {
            print("[RemoteAIConfig] Load failed: \(error.localizedDescription)")
            return nil
        }
    }
}
