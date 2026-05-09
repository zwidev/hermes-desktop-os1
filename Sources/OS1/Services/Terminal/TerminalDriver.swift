import Foundation
#if os(macOS)
import AppKit
#endif

public protocol TerminalDriver: Sendable {
    func setEventHandlers(
        onProcessStart: @escaping () -> Void,
        onTitleChange: @escaping (String) -> Void,
        onDirectoryChange: @escaping (String?) -> Void,
        onProcessExit: @escaping (Int32?) -> Void
    )

    #if os(macOS)
    func mount(
        in container: TerminalMountContainerView,
        appearance: TerminalThemeAppearance,
        isActive: Bool,
        launchToken: UUID
    )

    func unmount(from container: TerminalMountContainerView)
    #endif

    func terminate()
}
