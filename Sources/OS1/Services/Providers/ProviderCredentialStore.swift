import Foundation

/// Per-Mac wrapper for the user's LLM provider API keys.
final class ProviderCredentialStore: @unchecked Sendable {
    static let defaultProfileToken = "default"

    private let store: any CredentialStore
    private let service: String

    init(store: any CredentialStore, service: String = "ai.os1.provider-key") {
        self.store = store
        self.service = service
    }

    // MARK: - Read

    /// Resolves the API key for the given provider on the active host.
    /// Profile-scoped first; falls back to the Mac-level default.
    func loadAPIKey(slug: String, forProfileId profileId: String? = nil) -> String? {
        if let profileId, let key = readKey(account: account(profileToken: profileId, slug: slug)) {
            return key
        }
        return readKey(account: account(profileToken: Self.defaultProfileToken, slug: slug))
    }

    /// True if either a profile-specific or default key is stored.
    func hasAPIKey(slug: String, forProfileId profileId: String? = nil) -> Bool {
        loadAPIKey(slug: slug, forProfileId: profileId) != nil
    }

    /// True if there's a profile-scoped key (regardless of default).
    func hasProfileScopedKey(slug: String, profileId: String) -> Bool {
        readKey(account: account(profileToken: profileId, slug: slug)) != nil
    }

    /// Map of slug → has-any-key, used for rendering the provider list
    /// without N round-trips.
    func loadConnectionStatuses(forProfileId profileId: String?) -> [String: Bool] {
        var result: [String: Bool] = [:]
        for entry in ProviderCatalog.entries {
            result[entry.slug] = hasAPIKey(slug: entry.slug, forProfileId: profileId)
        }
        return result
    }

    // MARK: - Write

    /// Saves a key for one provider into a specific profile's slot.
    /// Empty input deletes that slot.
    func saveAPIKey(_ apiKey: String, slug: String, forProfileId profileId: String) throws {
        try saveKey(apiKey, account: account(profileToken: profileId, slug: slug))
    }

    /// Saves a key as the Mac-level default for one provider. Same
    /// empty-input semantics.
    func saveAsDefault(_ apiKey: String, slug: String) throws {
        try saveKey(apiKey, account: account(profileToken: Self.defaultProfileToken, slug: slug))
    }

    // MARK: - Delete

    func deleteKey(slug: String, forProfileId profileId: String) throws {
        try deleteKey(account: account(profileToken: profileId, slug: slug))
    }

    func deleteDefaultKey(slug: String) throws {
        try deleteKey(account: account(profileToken: Self.defaultProfileToken, slug: slug))
    }

    // MARK: - Internals

    private func account(profileToken: String, slug: String) -> String {
        "\(profileToken).\(slug)"
    }

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
