import Foundation
#if canImport(Combine)
import Combine
#endif

public final class TerminalTabModel: Identifiable {
    #if os(macOS)
    public let objectWillChange = ObservableObjectPublisher()
    #endif

    public let id = UUID()
    public let connectionID: UUID
    public let hostConnectionFingerprint: String
    public let workspaceScopeFingerprint: String
    public let session: TerminalSession
    public var title: String {
        didSet {
            #if os(macOS)
            objectWillChange.send()
            #endif
        }
    }

    public init(
        title: String,
        connectionID: UUID,
        hostConnectionFingerprint: String,
        workspaceScopeFingerprint: String,
        session: TerminalSession
    ) {
        self.title = title
        self.connectionID = connectionID
        self.hostConnectionFingerprint = hostConnectionFingerprint
        self.workspaceScopeFingerprint = workspaceScopeFingerprint
        self.session = session
    }
}

#if os(macOS)
extension TerminalTabModel: ObservableObject {}
#endif
