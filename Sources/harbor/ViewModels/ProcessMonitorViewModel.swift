import Foundation
import Observation
import AppKit

@MainActor @Observable
final class ProcessMonitorViewModel {
    var processes: [ServerProcess] = []
    var errorMessage: String?
    var isLoading = false
    var hasCompletedInitialLoad = false

    private let discoveryService = ProcessDiscoveryService()
    private let terminationService = ProcessTerminationService()
    private let persistenceService = PersistenceService()
    private var pollingTask: Task<Void, Never>?

    func startMonitoring() {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    func stopMonitoring() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let discovered = try await discoveryService.discoverListeningProcesses()
            let existingById = Dictionary(processes.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

            var merged: [ServerProcess] = []

            for item in discovered {
                if let existing = existingById[item.id] {
                    merged.append(existing)
                } else {
                    merged.append(item)
                }
            }

            processes = merged
            persistenceService.saveSessions(merged)
            errorMessage = nil
            hasCompletedInitialLoad = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func terminateProcess(_ process: ServerProcess) {
        do {
            try terminationService.terminate(pid: process.pid)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        processes.removeAll { $0.id == process.id }

        // If all siblings in the same process group are now gone, kill the group leader too
        if process.pgid > 0 {
            let remainingSiblings = processes.contains { $0.pgid == process.pgid }
            if !remainingSiblings {
                try? terminationService.terminate(pid: process.pgid)
            }
        }
    }

    func openInBrowser(_ process: ServerProcess) {
        guard let url = process.localURL else { return }
        NSWorkspace.shared.open(url)
    }
}
