import Foundation

/// Per-Mac wrapper for the user's Composio Connect API key(s).
final class ComposioCredentialStore: @unchecked Sendable {
    static let defaultAccount = "default"

    private let store: any CredentialStore
    private let service: String

    init(store: any CredentialStore, service: String = "dev.composio.connect.api-key") {
        self.store = store
        self.service = service
    }

    // MARK: - Read

    /// Resolves the API key for the active context. Profile-scoped first;
    /// falls back to the Mac-level default. Returns nil if nothing is
    /// stored at either tier.
    func loadAPIKey(forProfileId profileId: String? = nil) -> String? {
        if let profileId, let key = readKey(account: profileId) {
            return key
        }
        return readKey(account: Self.defaultAccount)
    }

    /// True if either a profile-specific or default key is stored.
    func hasAPIKey(forProfileId profileId: String? = nil) -> Bool {
        loadAPIKey(forProfileId: profileId) != nil
    }

    /// True if there's a profile-scoped key (regardless of default).
    func hasProfileScopedKey(profileId: String) -> Bool {
        readKey(account: profileId) != nil
    }

    // MARK: - Write

    /// Saves a key into a specific profile's slot. Empty input deletes
    /// that slot.
    func saveAPIKey(_ apiKey: String, forProfileId profileId: String) throws {
        try saveKey(apiKey, account: profileId)
    }

    /// Saves a key as the Mac-level default. Same semantics for empty.
    func saveAsDefault(_ apiKey: String) throws {
        try saveKey(apiKey, account: Self.defaultAccount)
    }

    // MARK: - Delete

    func deleteKey(forProfileId profileId: String) throws {
        try deleteKey(account: profileId)
    }

    func deleteDefaultKey() throws {
        try deleteKey(account: Self.defaultAccount)
    }

    // MARK: - Internals

    private func readKey(account: String) -> String? {
        store.load(service: service, account: account)
    }

    private func saveKey(_ apiKey: String, account: String) throws {
        try store.save(apiKey, service: service, account: account)
    }

    private func deleteKey(account: String) throws {
        try store.delete(service: service, account: account)
    }
}
