import Foundation

struct RemoteAIConfig: Decodable {
    let openaiApiKey: String?
    let groqApiKey: String?
    let openaiModel: String?
    let groqModel: String?
    let openaiEndpoint: String?
    let groqEndpoint: String?
    let systemPrompt: String?

    init(
        openaiApiKey: String?,
        groqApiKey: String?,
        openaiModel: String?,
        groqModel: String?,
        openaiEndpoint: String?,
        groqEndpoint: String?,
        systemPrompt: String?
    ) {
        self.openaiApiKey = openaiApiKey
        self.groqApiKey = groqApiKey
        self.openaiModel = openaiModel
        self.groqModel = groqModel
        self.openaiEndpoint = openaiEndpoint
        self.groqEndpoint = groqEndpoint
        self.systemPrompt = systemPrompt
    }

    var hasOpenAIKey: Bool {
        let key = (openaiApiKey ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
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
