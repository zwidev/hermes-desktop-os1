import Foundation
import ArgumentParser
import OS1Core

@main
struct OS1CLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "os1",
        abstract: "OS1 Command Line Interface for Linux",
        subcommands: [
            Connections.self,
            Voice.self
        ]
    )
}

extension OS1CLI {
    struct Connections: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Manage host connections",
            subcommands: [List.self, Add.self, Delete.self]
        )

        struct List: ParsableCommand {
            func run() throws {
                let paths = AppPaths()
                let store = ConnectionStore(paths: paths)
                let connections = store.connections
                if connections.isEmpty {
                    print("No connections configured.")
                } else {
                    for conn in connections {
                        print("- \(conn.label) (\(conn.id.uuidString))")
                        print("  Transport: \(conn.transport.kind)")
                        if case .ssh(let ssh) = conn.transport {
                            print("  SSH: \(ssh.user)@\(ssh.host):\(ssh.port ?? 22)")
                        }
                    }
                }
            }
        }

        struct Add: ParsableCommand {
            @Option(name: .shortAndLong, help: "Name of the connection")
            var name: String

            @Option(name: .shortAndLong, help: "SSH Host")
            var host: String

            @Option(name: .shortAndLong, help: "SSH User")
            var user: String = "root"

            @Option(name: .shortAndLong, help: "SSH Port")
            var port: Int = 22

            func run() throws {
                let paths = AppPaths()
                let store = ConnectionStore(paths: paths)
                let profile = ConnectionProfile(
                    label: name,
                    transport: .ssh(SSHConfig(alias: "", host: host, port: port, user: user))
                )
                store.upsert(profile)
                print("Added connection: \(name)")
            }
        }

        struct Delete: ParsableCommand {
            @Argument(help: "UUID of the connection to delete")
            var id: String

            func run() throws {
                guard let uuid = UUID(uuidString: id) else {
                    print("Invalid UUID: \(id)")
                    return
                }
                let paths = AppPaths()
                let store = ConnectionStore(paths: paths)
                if let conn = store.connections.first(where: { $0.id == uuid }) {
                    store.delete(conn)
                    print("Deleted connection: \(conn.label)")
                } else {
                    print("Connection not found: \(id)")
                }
            }
        }
    }

    struct Voice: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Start the Realtime voice bridge server"
        )

        @Option(name: .shortAndLong, help: "OpenAI API Key (or set OPENAI_API_KEY env var)")
        var apiKey: String?

        func run() async throws {
            if let apiKey {
                setenv("OPENAI_API_KEY", apiKey, 1)
            }

            let server = RealtimeVoiceSessionServer()
            server.start()

            if let url = server.endpointURL {
                print("Voice bridge server started at: \(url)")
                print("Status: \(server.statusText)")

                // Keep the process alive
                while true {
                    try await Task.sleep(nanoseconds: 1_000_000_000 * 60)
                }
            } else {
                print("Failed to start voice server: \(server.statusText)")
                if let error = server.lastError {
                    print("Error: \(error)")
                }
            }
        }
    }
}
