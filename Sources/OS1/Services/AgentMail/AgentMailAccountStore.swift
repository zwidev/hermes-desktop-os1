import Foundation
#if canImport(Combine)
import Combine
#endif

public struct AgentMailAccount: Codable, Equatable {
    public var humanEmail: String?
    public var primaryInboxId: String?
    public var organizationId: String?
    public var isVerified: Bool = false

    public init(humanEmail: String? = nil, primaryInboxId: String? = nil, organizationId: String? = nil, isVerified: Bool = false) {
        self.humanEmail = humanEmail
        self.primaryInboxId = primaryInboxId
        self.organizationId = organizationId
        self.isVerified = isVerified
    }
}

public final class AgentMailAccountStore: @unchecked Sendable {
    #if os(macOS)
    public let objectWillChange = ObservableObjectPublisher()
    #endif

    public static let defaultSlot = "default"
    public var account: AgentMailAccount? {
        didSet {
            #if os(macOS)
            objectWillChange.send()
            #endif
        }
    }

    private let userDefaults: UserDefaults
    private let baseKey: String
    private var activeProfileId: String?

    public init(
        userDefaults: UserDefaults = .standard,
        baseKey: String = "to.agentmail.account-metadata"
    ) {
        self.userDefaults = userDefaults
        self.baseKey = baseKey
        self.account = read(forSlot: Self.defaultSlot)
    }

    public func setActiveProfile(_ profileId: String?) {
        activeProfileId = profileId
        account = read(forSlot: profileId ?? Self.defaultSlot)
            ?? (profileId != nil ? read(forSlot: Self.defaultSlot) : nil)
    }

    public func update(_ updater: (inout AgentMailAccount) -> Void) {
        var current = account ?? AgentMailAccount()
        updater(&current)
        account = current
        persistActive()
    }

    public func setAccount(_ next: AgentMailAccount) {
        account = next
        persistActive()
    }

    public func clear() {
        account = nil
        if let activeProfileId {
            userDefaults.removeObject(forKey: storageKey(forSlot: activeProfileId))
        } else {
            userDefaults.removeObject(forKey: storageKey(forSlot: Self.defaultSlot))
        }
    }

    public func account(forProfileId profileId: String) -> AgentMailAccount? {
        read(forSlot: profileId) ?? read(forSlot: Self.defaultSlot)
    }

    public func setAccount(_ account: AgentMailAccount, forProfileId profileId: String) {
        write(account, toSlot: profileId)
        if activeProfileId == profileId {
            self.account = account
        }
    }

    public func clear(forProfileId profileId: String) {
        userDefaults.removeObject(forKey: storageKey(forSlot: profileId))
        if activeProfileId == profileId {
            account = nil
        }
    }

    private func persistActive() {
        guard let account else {
            if let activeProfileId {
                userDefaults.removeObject(forKey: storageKey(forSlot: activeProfileId))
            } else {
                userDefaults.removeObject(forKey: storageKey(forSlot: Self.defaultSlot))
            }
            return
        }
        write(account, toSlot: activeProfileId ?? Self.defaultSlot)
    }

    private func read(forSlot slot: String) -> AgentMailAccount? {
        guard let data = userDefaults.data(forKey: storageKey(forSlot: slot)) else { return nil }
        return try? JSONDecoder().decode(AgentMailAccount.self, from: data)
    }

    private func write(_ account: AgentMailAccount, toSlot slot: String) {
        guard let data = try? JSONEncoder().encode(account) else { return }
        userDefaults.set(data, forKey: storageKey(forSlot: slot))
    }

    private func storageKey(forSlot slot: String) -> String {
        slot == Self.defaultSlot ? baseKey : "\(baseKey).profile.\(slot)"
    }
}

#if os(macOS)
extension AgentMailAccountStore: ObservableObject {}
#endif
