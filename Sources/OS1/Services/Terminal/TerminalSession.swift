import Foundation
#if canImport(Combine)
import Combine
#endif

public final class TerminalSession: @unchecked Sendable {
    #if os(macOS)
    public let objectWillChange = ObservableObjectPublisher()
    #endif

    public let connection: ConnectionProfile
    private let driver: any TerminalDriver

    public var terminalTitle: String {
        didSet {
            #if os(macOS)
            objectWillChange.send()
            #endif
        }
    }
    public var currentDirectory: String? {
        didSet {
            #if os(macOS)
            objectWillChange.send()
            #endif
        }
    }
    public var exitCode: Int32? {
        didSet {
            #if os(macOS)
            objectWillChange.send()
            #endif
        }
    }
    public var didStart = false {
        didSet {
            #if os(macOS)
            objectWillChange.send()
            #endif
        }
    }
    public private(set) var launchToken = UUID() {
        didSet {
            #if os(macOS)
            objectWillChange.send()
            #endif
        }
    }
    public private(set) var isRunning = false {
        didSet {
            #if os(macOS)
            objectWillChange.send()
            #endif
        }
    }

    public init(
        connection: ConnectionProfile,
        sshTransport: SSHTransport,
        orgoTransport: OrgoTransport,
        startupCommandLine: String? = nil
    ) {
        self.connection = connection
        self.terminalTitle = "\(connection.label) · \(connection.resolvedHermesProfileName)"

        switch connection.transport {
        case .ssh:
            let sshArguments = sshTransport.shellArguments(
                for: connection,
                startupCommandLine: startupCommandLine
            )
            self.driver = TerminalViewHost(sshArguments: sshArguments)
        case .orgo(let cfg):
            self.driver = OrgoTerminalDriver(
                computerId: cfg.computerId,
                orgoTransport: orgoTransport
            )
        }

        driver.setEventHandlers(
            onProcessStart: { [weak self] in
                self?.markStarted()
            },
            onTitleChange: { [weak self] title in
                self?.updateTitle(title)
            },
            onDirectoryChange: { [weak self] directory in
                self?.currentDirectory = directory
            },
            onProcessExit: { [weak self] exitCode in
                self?.markExited(exitCode)
            }
        )
    }

    deinit {
        driver.terminate()
    }

    public func markStarted() {
        didStart = true
        isRunning = true
        exitCode = nil
    }

    public func updateTitle(_ title: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        terminalTitle = title
    }

    public func markExited(_ code: Int32?) {
        isRunning = false
        exitCode = code
    }

    public func requestReconnect() {
        currentDirectory = nil
        exitCode = nil
        launchToken = UUID()
    }

    #if os(macOS)
    public func mount(in container: TerminalMountContainerView, appearance: TerminalThemeAppearance, isActive: Bool) {
        driver.mount(
            in: container,
            appearance: appearance,
            isActive: isActive,
            launchToken: launchToken
        )
    }

    public func unmount(from container: TerminalMountContainerView) {
        driver.unmount(from: container)
    }
    #endif

    public func stop() {
        driver.terminate()
        isRunning = false
        currentDirectory = nil
    }
}

#if os(macOS)
extension TerminalSession: ObservableObject {}
#endif
