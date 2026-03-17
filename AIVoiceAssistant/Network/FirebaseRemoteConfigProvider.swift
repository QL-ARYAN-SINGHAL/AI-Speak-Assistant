import Foundation
import FirebaseRemoteConfig

final class FirebaseRemoteConfigProvider {
    private let remoteConfig: RemoteConfig
    private let store: RemoteAIConfigStore

    init(store: RemoteAIConfigStore) {
        self.store = store
        self.remoteConfig = RemoteConfig.remoteConfig()

        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings

        do {
            try remoteConfig.setDefaults(from: [
                "openai_api_key": "",
                "groq_api_key": "",
                "openai_model": "gpt-4o-mini",
                "groq_model": "llama-3.1-8b-instant",
                "openai_endpoint": "",
                "groq_endpoint": "",
                "system_prompt": "You are a helpful, concise voice assistant."
            ])
        } catch {
            print("[RemoteConfig] Default values failed: \(error.localizedDescription)")
        }
    }

    func fetchAndActivate() async {
        do {
            let status = try await remoteConfig.fetchAndActivate()
            print("[RemoteConfig] fetchAndActivate status: \(status.rawValue)")
        } catch {
            print("[RemoteConfig] Fetch failed: \(error.localizedDescription)")
        }

        let config = RemoteAIConfig(
            openaiApiKey: remoteConfig["openai_api_key"].stringValue,
            groqApiKey: remoteConfig["groq_api_key"].stringValue,
            openaiModel: remoteConfig["openai_model"].stringValue,
            groqModel: remoteConfig["groq_model"].stringValue,
            openaiEndpoint: remoteConfig["openai_endpoint"].stringValue,
            groqEndpoint: remoteConfig["groq_endpoint"].stringValue,
            systemPrompt: remoteConfig["system_prompt"].stringValue
        )

        store.update(config)
        print("[RemoteConfig] Updated remote AI config")
        print("[RemoteConfig] OpenAI key config \(config.openaiApiKey ?? "Key not got")")
        print("[RemoteConfig] Groq key config \(config.groqApiKey ?? "Key not got")")
        print("[RemoteConfig] Updated remote AI config")
        print("[RemoteConfig] openai_api_key set: \(config.openaiApiKey?.isEmpty == false)")
        print("[RemoteConfig] groq_api_key set: \(config.groqApiKey?.isEmpty == false)")
        print("[RemoteConfig] openai_model: \(config.openaiModel ?? "")")
        print("[RemoteConfig] groq_model: \(config.groqModel ?? "")")
        print("[RemoteConfig] openai_endpoint: \(config.openaiEndpoint ?? "")")
        print("[RemoteConfig] groq_endpoint: \(config.groqEndpoint ?? "")")
    }
}
