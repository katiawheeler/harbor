# Release Notes

## v1.0.0

Harbor is a native macOS menu bar app for monitoring and managing local development server processes. This is the initial release. Install it, run it, and it works — no configuration required.

### Features

- **Menu bar integration** — runs as a background app (`LSUIElement`) with a `ferry.fill` SF Symbol icon; left-click to open the server list, right-click to quit
- **Automatic server discovery** — scans listening TCP processes via `lsof` and filters to known runtimes: Node.js, Python, Ruby, Go, Rust, Deno, Bun, PHP, Java, .NET, and Elixir
- **Smart project naming** — resolves human-readable project names from manifest files (`package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `mix.exs`, and others); falls back to directory name
- **Per-server detail** — each entry displays project name, command, PID, port, and current status at a glance
- **Open in browser** — one-click to open `localhost:<port>` in the default browser
- **Graceful termination** — kill a process with a confirmation step; sends `SIGTERM` first, escalates to `SIGKILL` if needed
- **Search and filter** — filter the server list by name, port, or PID
- **Live polling** — refreshes the server list every 3 seconds automatically
- **Theme support** — choose light, dark, or system appearance; preference persists across launches
- **Zero dependencies** — pure Swift/SwiftUI, no third-party libraries or external tooling required
- **Free**

### Requirements

- macOS 15.0 or later
