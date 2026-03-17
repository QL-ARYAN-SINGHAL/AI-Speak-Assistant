import Foundation

final class RemoteAIConfigStore {
    private let lock = NSLock()
    private var config: RemoteAIConfig?

    func update(_ config: RemoteAIConfig) {
        lock.lock()
        self.config = config
        lock.unlock()
    }

    func currentConfig() -> RemoteAIConfig? {
        lock.lock()
        let value = config
        lock.unlock()
        return value
    }
}
