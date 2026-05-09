import Foundation
#if canImport(Combine)
import Combine
#endif

public final class ConnectionStore: @unchecked Sendable {
    #if os(macOS)
    public let objectWillChange = ObservableObjectPublisher()
    #endif

    public var connections: [ConnectionProfile] = [] {
        didSet {
            #if os(macOS)
            objectWillChange.send()
            #endif
        }
    }
    public var persistenceError: String? {
        didSet {
            #if os(macOS)
            objectWillChange.send()
            #endif
        }
    }
    public var lastConnectionID: UUID? {
        didSet {
            savePreferences()
            #if os(macOS)
            objectWillChange.send()
            #endif
        }
    }
    public var terminalTheme: TerminalThemePreference = .defaultValue {
        didSet {
            savePreferences()
            #if os(macOS)
            objectWillChange.send()
            #endif
        }
    }
    public var workspaceFileBookmarks: [WorkspaceFileBookmark] = [] {
        didSet {
            savePreferences()
            #if os(macOS)
            objectWillChange.send()
            #endif
        }
    }
    public var pinnedSessions: [PinnedSession] = [] {
        didSet {
            savePreferences()
            #if os(macOS)
            objectWillChange.send()
            #endif
        }
    }

    private let paths: AppPaths
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(paths: AppPaths) {
        self.paths = paths
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        load()
    }

    public func upsert(_ connection: ConnectionProfile) {
        let normalized = connection.updated()
        if let index = connections.firstIndex(where: { $0.id == normalized.id }) {
            connections[index] = normalized
        } else {
            connections.append(normalized)
        }
        connections.sort { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
        saveConnections()
    }

    public func delete(_ connection: ConnectionProfile) {
        connections.removeAll(where: { $0.id == connection.id })
        if lastConnectionID == connection.id {
            lastConnectionID = nil
        }
        saveConnections()
    }

    public func bookmarks(for workspaceScopeFingerprint: String) -> [WorkspaceFileBookmark] {
        workspaceFileBookmarks
            .filter { $0.workspaceScopeFingerprint == workspaceScopeFingerprint }
            .sorted { lhs, rhs in
                lhs.displayTitle.localizedCaseInsensitiveCompare(rhs.displayTitle) == .orderedAscending
            }
    }

    @discardableResult
    public func upsertWorkspaceFileBookmark(
        remotePath: String,
        title: String? = nil,
        workspaceScopeFingerprint: String
    ) -> WorkspaceFileBookmark? {
        let normalizedPath = remotePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedPath.isEmpty else { return nil }
        let normalizedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        if let index = workspaceFileBookmarks.firstIndex(where: {
            $0.workspaceScopeFingerprint == workspaceScopeFingerprint &&
                $0.remotePath == normalizedPath
        }) {
            var bookmark = workspaceFileBookmarks[index]
            bookmark.title = normalizedTitle ?? bookmark.title
            bookmark.updatedAt = Date()
            workspaceFileBookmarks[index] = bookmark
            savePreferences()
            return bookmark
        }

        let bookmark = WorkspaceFileBookmark(
            workspaceScopeFingerprint: workspaceScopeFingerprint,
            remotePath: normalizedPath,
            title: normalizedTitle
        )
        workspaceFileBookmarks.append(bookmark)
        savePreferences()
        return bookmark
    }

    public func removeWorkspaceFileBookmark(id: UUID) {
        workspaceFileBookmarks.removeAll { $0.id == id }
        savePreferences()
    }

    public func pinnedSessions(for workspaceScopeFingerprint: String) -> [PinnedSession] {
        pinnedSessions
            .filter { $0.workspaceScopeFingerprint == workspaceScopeFingerprint }
            .sorted { lhs, rhs in
                lhs.createdAt > rhs.createdAt
            }
    }

    public func isSessionPinned(id: String, workspaceScopeFingerprint: String) -> Bool {
        pinnedSessions.contains {
            $0.workspaceScopeFingerprint == workspaceScopeFingerprint &&
                $0.id == id
        }
    }

    public func upsertPinnedSession(_ session: SessionSummary, workspaceScopeFingerprint: String) {
        if let index = pinnedSessions.firstIndex(where: {
            $0.workspaceScopeFingerprint == workspaceScopeFingerprint &&
                $0.id == session.id
        }) {
            var pinnedSession = pinnedSessions[index]
            pinnedSession.title = session.title
            pinnedSession.model = session.model
            pinnedSession.startedAt = session.startedAt
            pinnedSession.lastActive = session.lastActive
            pinnedSession.messageCount = session.messageCount
            pinnedSession.preview = session.preview
            pinnedSession.updatedAt = Date()
            pinnedSessions[index] = pinnedSession
        } else {
            pinnedSessions.append(
                PinnedSession(
                    session: session,
                    workspaceScopeFingerprint: workspaceScopeFingerprint
                )
            )
        }
        savePreferences()
    }

    public func removePinnedSession(id: String, workspaceScopeFingerprint: String) {
        pinnedSessions.removeAll {
            $0.workspaceScopeFingerprint == workspaceScopeFingerprint &&
                $0.id == id
        }
        savePreferences()
    }

    private func load() {
        loadConnections()
        loadPreferences()
    }

    private func saveConnections() {
        do {
            let data = try encoder.encode(connections)
            try data.write(to: paths.connectionsURL, options: [.atomic])
            try setPrivatePermissions(at: paths.connectionsURL)
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    private func savePreferences() {
        let preferences = AppPreferences(
            lastConnectionID: lastConnectionID,
            terminalTheme: terminalTheme,
            workspaceFileBookmarks: workspaceFileBookmarks,
            pinnedSessions: pinnedSessions
        )
        do {
            let data = try encoder.encode(preferences)
            try data.write(to: paths.preferencesURL, options: [.atomic])
            try setPrivatePermissions(at: paths.preferencesURL)
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    private func loadConnections() {
        do {
            let data = try Data(contentsOf: paths.connectionsURL)
            connections = try decoder.decode([ConnectionProfile].self, from: data)
        } catch {
            connections = []
        }
    }

    private func loadPreferences() {
        do {
            let data = try Data(contentsOf: paths.preferencesURL)
            let decoded = try decoder.decode(AppPreferences.self, from: data)
            lastConnectionID = decoded.lastConnectionID
            terminalTheme = decoded.terminalTheme ?? .defaultValue
            workspaceFileBookmarks = decoded.workspaceFileBookmarks ?? []
            pinnedSessions = decoded.pinnedSessions ?? []
        } catch {
            lastConnectionID = nil
            terminalTheme = .defaultValue
            workspaceFileBookmarks = []
            pinnedSessions = []
        }
    }

    private func setPrivatePermissions(at url: URL) throws {
        #if !os(Windows)
        let attributes: [FileAttributeKey: Any] = [.posixPermissions: 0o600]
        try? paths.fileManager.setAttributes(attributes, ofItemAtPath: url.path)
        #endif
    }
}

#if os(macOS)
extension ConnectionStore: ObservableObject {}
#endif

private struct AppPreferences: Codable {
    var lastConnectionID: UUID?
    var terminalTheme: TerminalThemePreference?
    var workspaceFileBookmarks: [WorkspaceFileBookmark]?
    var pinnedSessions: [PinnedSession]?
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
