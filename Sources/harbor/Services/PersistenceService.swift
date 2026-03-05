import Foundation

struct PersistenceService: Sendable {
    private static let key = "harbor.knownSessions"

    func loadSessions() -> [ServerProcess] {
        guard let data = UserDefaults.standard.data(forKey: Self.key),
              let sessions = try? JSONDecoder().decode([ServerProcess].self, from: data)
        else { return [] }
        return sessions
    }

    func saveSessions(_ sessions: [ServerProcess]) {
        let data = try? JSONEncoder().encode(sessions)
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}
