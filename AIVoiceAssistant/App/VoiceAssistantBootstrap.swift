import Foundation

enum VoiceAssistantBootstrap {
    static func makeViewModel() -> VoiceAssistantViewModel {
        if let remoteConfig = RemoteAIConfig.loadFromBundle() {
            if let remoteEngine = FailoverAIEngine(config: remoteConfig) {
                let prompt = remoteConfig.systemPrompt ?? "You are a helpful, concise voice assistant."
                let service = DefaultLLMService(engine: remoteEngine, systemPrompt: prompt)
                return VoiceAssistantViewModel(manager: VoiceConversationManager(llmService: service))
            }
        }

        let fallbackService = DefaultLLMService(
            engine: SimpleLocalAIEngine(),
            systemPrompt: "You are a helpful, concise voice assistant."
        )
        let vm = VoiceAssistantViewModel(manager: VoiceConversationManager(llmService: fallbackService))
        vm.setError("No remote AI configured. Add RemoteAIConfig.json.")
        return vm
    }
}
