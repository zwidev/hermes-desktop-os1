import Foundation

public protocol CredentialStore: Sendable {
    func load(service: String, account: String) -> String?
    func save(_ value: String, service: String, account: String) throws
    func delete(service: String, account: String) throws
}

public enum CredentialStoreError: LocalizedError {
    case saveFailed(String)
    case deleteFailed(String)

    public var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "Failed to save credential: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete credential: \(message)"
        }
    }
}
