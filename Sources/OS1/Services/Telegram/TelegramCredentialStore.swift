import Foundation

/// Per-Mac wrapper for the user's Telegram Bot token.
final class TelegramCredentialStore: @unchecked Sendable {
    private let store: any CredentialStore
    private let service: String
    private let account: String

    init(store: any CredentialStore, service: String = "ai.os1.telegram-bot-token", account: String = "default") {
        self.store = store
        self.service = service
        self.account = account
    }

    func loadBotToken() -> String? {
        store.load(service: service, account: account)
    }

    var hasBotToken: Bool {
        loadBotToken() != nil
    }

    func saveBotToken(_ token: String) throws {
        try store.save(token, service: service, account: account)
    }

    func deleteBotToken() throws {
        try store.delete(service: service, account: account)
    }
}
