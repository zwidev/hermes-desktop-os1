import Foundation
#if canImport(Combine)
import Combine
#endif

public final class TerminalWorkspaceStore: @unchecked Sendable {
    #if os(macOS)
    public let objectWillChange = ObservableObjectPublisher()
    #endif

    public var tabs: [TerminalTabModel] = [] {
        didSet {
            #if os(macOS)
            objectWillChange.send()
            #endif
        }
    }
    public var selectedTabID: UUID? {
        didSet {
            #if os(macOS)
            objectWillChange.send()
            #endif
        }
    }

    private let sshTransport: SSHTransport
    private let orgoTransport: OrgoTransport

    public init(sshTransport: SSHTransport, orgoTransport: OrgoTransport) {
        self.sshTransport = sshTransport
        self.orgoTransport = orgoTransport
    }

    public var selectedTab: TerminalTabModel? {
        guard let selectedTabID else { return nil }
        return tabs.first(where: { $0.id == selectedTabID })
    }

    public var hasTabs: Bool {
        !tabs.isEmpty
    }

    public func selectTab(_ tabID: UUID?) {
        selectedTabID = tabID
    }

    public func ensureInitialTab(for connection: ConnectionProfile) {
        if let existingTab = existingTab(for: connection.workspaceScopeFingerprint) {
            selectTab(existingTab.id)
        } else {
            addTab(for: connection)
        }
    }

    @discardableResult
    public func addCommandTab(for connection: ConnectionProfile, commandLine: String) -> TerminalTabModel {
        addTab(for: connection, startupCommandLine: commandLine)
    }

    @discardableResult
    public func addTab(for connection: ConnectionProfile, startupCommandLine: String? = nil) -> TerminalTabModel {
        let session = TerminalSession(
            connection: connection,
            sshTransport: sshTransport,
            orgoTransport: orgoTransport,
            startupCommandLine: startupCommandLine
        )
        let tab = TerminalTabModel(
            title: connection.label,
            connectionID: connection.id,
            hostConnectionFingerprint: connection.hostConnectionFingerprint,
            workspaceScopeFingerprint: connection.workspaceScopeFingerprint,
            session: session
        )
        tabs.append(tab)
        selectTab(tab.id)
        return tab
    }

    public func closeTab(_ tab: TerminalTabModel) {
        if selectedTabID == tab.id {
            selectTab(tabs.last(where: { $0.id != tab.id })?.id)
        }
        tabs.removeAll(where: { $0.id == tab.id })
        tab.session.stop()
    }

    public func closeAllTabs() {
        for tab in tabs {
            tab.session.stop()
        }
        tabs = []
        selectTab(nil)
    }

    public func closeTabs(forConnectionID connectionID: UUID) {
        let removedTabs = tabs.filter { $0.connectionID == connectionID }
        let removedTabIDs = Set(removedTabs.map(\.id))

        if let selectedTabID, removedTabIDs.contains(selectedTabID) {
            selectTab(tabs.last(where: { !removedTabIDs.contains($0.id) })?.id)
        }

        tabs.removeAll(where: { $0.connectionID == connectionID })

        for tab in removedTabs {
            tab.session.stop()
        }
    }

    private func existingTab(for workspaceScopeFingerprint: String) -> TerminalTabModel? {
        tabs.last(where: { $0.workspaceScopeFingerprint == workspaceScopeFingerprint })
    }
}

#if os(macOS)
extension TerminalWorkspaceStore: ObservableObject {}
#endif
