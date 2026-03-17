import Foundation

enum VoiceAssistantBootstrap {
    static func makeViewModel() -> VoiceAssistantViewModel {
        let store = RemoteAIConfigStore()

        if let localConfig = RemoteAIConfig.loadFromBundle() {
            store.update(localConfig)
        }

        let remoteProvider = FirebaseRemoteConfigProvider(store: store)
        Task {
            await remoteProvider.fetchAndActivate()
        }

        let prompt = store.currentConfig()?.systemPrompt ?? "You are a helpful, concise voice assistant."
        let engine = DynamicRemoteAIEngine(store: store, fallback: SimpleLocalAIEngine())
        let service = DefaultLLMService(engine: engine, systemPrompt: prompt)
        return VoiceAssistantViewModel(manager: VoiceConversationManager(llmService: service))
    }
}
