import Foundation

struct ProcessDiscoveryService: Sendable {
    func discoverListeningProcesses() async throws -> [ServerProcess] {
        // Get current user's username
        let currentUser = NSUserName()
        
        let output = try await runCommand(
            "/usr/sbin/lsof",
            arguments: ["-iTCP", "-sTCP:LISTEN", "-n", "-P", "-u", currentUser]
        )
        return await parseLsofOutput(output)
    }

    private func runCommand(_ path: String, arguments: [String]) async throws -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }

    private static let devServerPrefixes: [String] = [
        "node", "npm", "npx", "deno", "bun",
        "python", "python3", "uvicorn", "gunicorn", "flask", "django",
        "ruby", "rails", "puma", "thin", "unicorn",
        "java", "gradle", "mvn", "spring",
        "go", "air", "dlv",
        "cargo", "rustc",
        "php", "php-fpm", "artisan",
        "dotnet", "kestrel",
        "next-server", "vite", "webpack", "esbuild", "tsx", "ts-node",
        "nginx", "caddy", "traefik",
        "swift", "vapor",
        "redis-server", "mongod", "postgres", "mysqld",
        "docker-proxy",
        "beam.smp", "mix", "elixir", "erl",
    ]

    private func isDevServerProcess(command: String) -> Bool {
        let cmd = command.lowercased()
        return Self.devServerPrefixes.contains { cmd.hasPrefix($0) }
    }

    private func parseLsofOutput(_ output: String) async -> [ServerProcess] {
        let lines = output.components(separatedBy: "\n")
        var seen: Set<String> = []
        var processes: [ServerProcess] = []

        for line in lines.dropFirst() {
            let columns = line.split(separator: " ", omittingEmptySubsequences: true)
            guard columns.count >= 9 else { continue }

            let command = String(columns[0])
            guard let pid = Int32(columns[1]) else { continue }

            let nameColumn = String(columns[columns.count - 2])
            guard let port = extractPort(from: nameColumn) else { continue }

            guard isDevServerProcess(command: command) else { continue }

            let key = "\(pid):\(port)"
            guard !seen.contains(key) else { continue }
            seen.insert(key)

            let displayName = await resolveDisplayName(pid: pid, command: command)
            let pgid = getpgid(pid)
            processes.append(ServerProcess(pid: pid, pgid: pgid, name: displayName, command: command, port: port))
        }

        return processes
    }

    private func resolveDisplayName(pid: Int32, command: String) async -> String {
        guard let cwd = try? await getProcessCwd(pid: pid) else {
            return command
        }

        let projectManifests: [(file: String, nameKey: String?)] = [
            ("package.json", "name"),
            ("Cargo.toml", "name"),
            ("pubspec.yaml", "name"),
            ("mix.exs", nil),
            ("go.mod", nil),
            ("pyproject.toml", "name"),
            ("setup.py", nil),
        ]

        for manifest in projectManifests {
            let path = (cwd as NSString).appendingPathComponent(manifest.file)
            guard FileManager.default.fileExists(atPath: path) else { continue }

            if let nameKey = manifest.nameKey,
               let name = extractNameFromFile(atPath: path, key: nameKey) {
                return name
            }

            return (cwd as NSString).lastPathComponent
        }

        return (cwd as NSString).lastPathComponent
    }

    private func getProcessCwd(pid: Int32) async throws -> String {
        let output = try await runCommand(
            "/usr/sbin/lsof",
            arguments: ["-p", String(pid), "-a", "-d", "cwd", "-Fn"]
        )
        for line in output.components(separatedBy: "\n") {
            if line.hasPrefix("n") && line.count > 1 {
                return String(line.dropFirst())
            }
        }
        throw ProcessDiscoveryError.cwdNotFound
    }

    private func extractNameFromFile(atPath path: String, key: String) -> String? {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        if path.hasSuffix(".json") {
            return extractJSONValue(from: content, key: key)
        }

        if path.hasSuffix(".toml") {
            return extractTOMLValue(from: content, key: key)
        }

        if path.hasSuffix(".yaml") || path.hasSuffix(".yml") {
            return extractYAMLValue(from: content, key: key)
        }

        return nil
    }

    private func extractJSONValue(from content: String, key: String) -> String? {
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let value = json[key] as? String,
              !value.isEmpty else {
            return nil
        }
        return value
    }

    private func extractTOMLValue(from content: String, key: String) -> String? {
        let pattern = #"^\s*"# + NSRegularExpression.escapedPattern(for: key) + #"\s*=\s*"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) else {
            return nil
        }
        let range = NSRange(content.startIndex..., in: content)
        guard let match = regex.firstMatch(in: content, range: range),
              let valueRange = Range(match.range(at: 1), in: content) else {
            return nil
        }
        let value = String(content[valueRange])
        return value.isEmpty ? nil : value
    }

    private func extractYAMLValue(from content: String, key: String) -> String? {
        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("\(key):") {
                let value = trimmed.dropFirst(key.count + 1).trimmingCharacters(in: .whitespaces)
                let cleaned = value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                return cleaned.isEmpty ? nil : cleaned
            }
        }
        return nil
    }

    private enum ProcessDiscoveryError: Error {
        case cwdNotFound
    }

    private func extractPort(from address: String) -> UInt16? {
        guard let colonIndex = address.lastIndex(of: ":") else { return nil }
        let portString = address[address.index(after: colonIndex)...]
        return UInt16(portString)
    }
}
