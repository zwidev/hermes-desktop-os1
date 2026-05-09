import Foundation

/// Per-Mac wrapper for the global Orgo API key.
final class OrgoCredentialStore: @unchecked Sendable {
    private let store: any CredentialStore
    private let service: String
    private let account: String

    init(store: any CredentialStore, service: String = "ai.orgo.mac.api-key", account: String = "default") {
        self.store = store
        self.service = service
        self.account = account
    }

    /// Returns the stored API key, or nil if none has been saved.
    func loadAPIKey() -> String? {
        store.load(service: service, account: account)
    }

    /// True if a (non-empty) API key is currently stored.
    var hasAPIKey: Bool {
        loadAPIKey() != nil
    }

    /// Saves the API key, replacing any existing value. Empty/whitespace input
    /// is treated as a delete to keep the store from carrying empty entries.
    func saveAPIKey(_ apiKey: String) throws {
        try store.save(apiKey, service: service, account: account)
    }

    /// Removes the API key. No-op if none is stored.
    func deleteAPIKey() throws {
        try store.delete(service: service, account: account)
    }
}
