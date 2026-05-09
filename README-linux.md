# OS1 for Linux (Ubuntu)

This project has been refactored to support Linux, specifically for headless environments like Hetzner servers running Ubuntu.

## Features

- **os1-cli**: A command-line tool to manage connections and run the Realtime voice bridge.
- **Portable Credentials**: Uses file-based storage with restricted permissions (600) when Keychain is unavailable.
- **NIO-based Voice Server**: Replaced macOS-only `Network.framework` with `SwiftNIO` for the voice bridge.

## Installation

### Prerequisites

- Swift 6.0 or newer
- Ubuntu 22.04 or 24.04 recommended

### Building from Source

```bash
swift build -c release --product os1-cli
```

The binary will be located at `.build/release/os1-cli`. You can move it to your path:

```bash
sudo cp .build/release/os1-cli /usr/local/bin/os1
```

## Usage

### Manage Connections

List connections:
```bash
os1 connections list
```

Add an SSH connection:
```bash
os1 connections add --name "My VPS" --host "1.2.3.4" --user root
```

### Start Realtime Voice Bridge

The voice bridge allows an AI agent to talk to you. It requires an OpenAI API key.

```bash
export OPENAI_API_KEY="sk-..."
os1 voice
```

Or pass it as an option:
```bash
os1 voice --api-key "sk-..."
```

## Docker Deployment

You can run OS1 in a Docker container:

```bash
docker build -t os1 .
docker run -it -e OPENAI_API_KEY="sk-..." os1 voice
```

## Configuration

Configuration and credentials are stored in `~/.config/os1/`.
- `connections.json`: Your saved hosts.
- `credentials/`: Securely stored API keys.
