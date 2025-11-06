#!/bin/bash

DEFAULT_PORT=7777
PORT=$DEFAULT_PORT
SCENE_PATH="networking/server/server.tscn"

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --port PORT    Set server port (default: $DEFAULT_PORT)"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Example:"
    echo "  $0                 Start server on default port"
    echo "  $0 -p 8888         Start server on port 8888"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "  OpenSlender Dedicated Server"
echo "=========================================="
echo "Port: $PORT"
echo "Max Players: 10"
echo "=========================================="
echo ""

godot --headless "$SCENE_PATH" -- --server --port="$PORT"

