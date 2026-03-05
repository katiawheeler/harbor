# Harbor

A macOS menu bar app for monitoring and managing local dev server processes.

## What It Does

Harbor lives in your menu bar and keeps track of every dev server running on your machine. Left-click the ferry icon to see all running servers; right-click for a Quit option.

Each server entry shows the project name, process, PID, and port — with one-click buttons to open it in your browser or terminate it.

## Features

- **Auto-discovery** — scans listening TCP processes via `lsof`, filtering to known runtimes: Node, Python, Bun, Deno, Go, Ruby, Cargo, and more
- **Smart naming** — resolves project names from `package.json`, `Cargo.toml`, `pyproject.toml`, etc.; falls back to directory name
- **Open in browser** — click to open `localhost:<port>` directly
- **Terminate with confirmation** — inline confirm step before killing a process
- **Process group awareness** — kills sibling processes together; only removes the group leader (terminal shell) once all siblings are gone
- **Theme toggle** — light, dark, or system; persisted across launches
- **Live updates** — polls every 3 seconds

## Release Notes

See [RELEASE_NOTES.md](RELEASE_NOTES.md) for version history.

## Requirements

- macOS 15+
- Swift 6.2+

## Build & Run

```bash
# Build
swift build

# Run
swift run harbor
```

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 6.2 |
| UI | SwiftUI, NSStatusItem, NSPopover |
| State | `@Observable` + `@MainActor` |
| Build | Swift Package Manager |
| Process discovery | `lsof` |
| Persistence | `UserDefaults` |
