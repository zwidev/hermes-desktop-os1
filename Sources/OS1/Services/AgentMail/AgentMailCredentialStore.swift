import Foundation

/// Per-Mac wrapper for the Agent Mail bridge API key.
final class AgentMailCredentialStore: @unchecked Sendable {
    private let store: any CredentialStore
    private let service: String
    private let account: String

    init(store: any CredentialStore, service: String = "ai.os1.agent-mail-key", account: String = "default") {
        self.store = store
        self.service = service
        self.account = account
    }

    func loadAPIKey() -> String? {
        store.load(service: service, account: account)
    }

    var hasAPIKey: Bool {
        loadAPIKey() != nil
    }

    func saveAPIKey(_ apiKey: String) throws {
        try store.save(apiKey, service: service, account: account)
    }

    func deleteAPIKey() throws {
        try store.delete(service: service, account: account)
    }
}
