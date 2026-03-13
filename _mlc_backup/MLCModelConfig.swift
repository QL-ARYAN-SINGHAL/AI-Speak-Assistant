import Foundation

struct MLCModelConfig: Decodable {
    let modelPath: String
    let modelLib: String
    let systemPrompt: String
    let maxTokens: Int?
    let temperature: Double?

    static func loadFromBundle() -> MLCModelConfig? {
        guard let url = Bundle.main.url(forResource: "MLCModelConfig", withExtension: "json") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(MLCModelConfig.self, from: data)
        } catch {
            return nil
        }
    }
}
