import Foundation

public final class FileCredentialStore: CredentialStore, @unchecked Sendable {
    private let rootURL: URL
    private let fileManager: FileManager

    public init(rootURL: URL, fileManager: FileManager = .default) {
        self.rootURL = rootURL
        self.fileManager = fileManager
        try? fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
    }

    private func fileURL(service: String, account: String) -> URL {
        // Simple sanitization: Replace non-alphanumeric with underscores to avoid path injection
        let safeService = service.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "_")
        let safeAccount = account.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "_")
        return rootURL.appendingPathComponent("\(safeService)__\(safeAccount).txt")
    }

    public func load(service: String, account: String) -> String? {
        let url = fileURL(service: service, account: account)
        guard let data = try? Data(contentsOf: url),
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    public func save(_ value: String, service: String, account: String) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            try delete(service: service, account: account)
            return
        }

        let url = fileURL(service: service, account: account)
        let data = Data(trimmed.utf8)

        try data.write(to: url, options: .atomic)

        // Ensure 600 permissions
        #if !os(Windows)
        let attributes: [FileAttributeKey: Any] = [.posixPermissions: 0o600]
        try? fileManager.setAttributes(attributes, ofItemAtPath: url.path)
        #endif
    }

    public func delete(service: String, account: String) throws {
        let url = fileURL(service: service, account: account)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
}
