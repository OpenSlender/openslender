# OpenSlender Networking

This directory contains the networking implementation for OpenSlender's multiplayer functionality.

## Structure

- `client/` - Client-side connection and UI
- `server/` - Dedicated server implementation
- `shared/` - Shared constants and utilities

## Quick Start

### Running the Dedicated Server

```bash
# From project root
godot --headless networking/server/server.tscn -- --server --port=7777
```

Or use the provided script:

```bash
cd networking/server
./start_server.sh
```

### Running the Client

1. Open the project in Godot
2. Run the `networking/client/client.tscn` scene
3. Enter server address (default: 127.0.0.1)
4. Enter port (default: 7777)
5. Click "Connect"

## Features

### Server
- Multi-peer ENet server
- Connection tracking
- Configurable port and max players

### Client
- UI for connecting to servers
- Real-time player list
- Connection status display
- Shows peer ID for each connected player

## Architecture

The networking layer uses Godot's high-level multiplayer API with ENet as the transport layer.

### Server Architecture
- `ServerLauncher.gd` - Handles command-line arguments and initializes server
- `DedicatedServer.gd` - Core server logic, peer management

### Client Architecture
- `ClientConnection.gd` - Handles connection to server and network events
- `ClientUI.gd` - User interface for connection management and player list

## Constants

Default values are defined in `shared/NetworkConstants.gd`:
- Default port: 7777
- Default address: 127.0.0.1
- Max players: 10
