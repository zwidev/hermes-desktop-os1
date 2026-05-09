import CryptoKit
import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public struct AppPaths: Sendable {
    public let fileManager: FileManager
    public let applicationSupportURL: URL
    public let connectionsURL: URL
    public let preferencesURL: URL
    public let controlSocketDirectoryURL: URL

    private static let privateDirectoryPermissions = NSNumber(value: Int16(0o700))

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        #if os(macOS)
        let baseSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let appSupport = baseSupport.appendingPathComponent("OS1", isDirectory: true)
        #else
        let homeDir = URL(fileURLWithPath: String(cString: getpwuid(getuid()).pointee.pw_dir), isDirectory: true)
        let appSupport = homeDir.appendingPathComponent(".config/os1", isDirectory: true)
        #endif

        let controlDirectory = URL(
            fileURLWithPath: "/tmp/hd-\(getuid())",
            isDirectory: true
        )

        self.applicationSupportURL = appSupport
        self.connectionsURL = appSupport.appendingPathComponent("connections.json")
        self.preferencesURL = appSupport.appendingPathComponent("preferences.json")
        self.controlSocketDirectoryURL = controlDirectory

        createPrivateDirectoryIfNeeded(at: appSupport)
        createPrivateDirectoryIfNeeded(at: controlDirectory)
    }

    public func controlPath(for connection: ConnectionProfile) -> String {
        createPrivateDirectoryIfNeeded(at: controlSocketDirectoryURL)

        return controlSocketDirectoryURL
            .appendingPathComponent(controlSocketIdentifier(for: connection))
            .path
    }

    private func createPrivateDirectoryIfNeeded(at url: URL) {
        #if !os(Windows)
        let attributes: [FileAttributeKey: Any] = [
            .posixPermissions: Self.privateDirectoryPermissions
        ]
        #endif

        if !fileManager.fileExists(atPath: url.path) {
            #if os(Windows)
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            #else
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: attributes)
            #endif
        } else {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
               !isDirectory.boolValue {
                return
            }
        }

        #if !os(Windows)
        try? fileManager.setAttributes(attributes, ofItemAtPath: url.path)
        #endif
    }

    private func controlSocketIdentifier(for connection: ConnectionProfile) -> String {
        let digest = SHA256.hash(data: Data(connection.workspaceScopeFingerprint.utf8))
        let hexDigest = digest.map { String(format: "%02x", $0) }.joined()
        return String(hexDigest.prefix(24))
    }
}
