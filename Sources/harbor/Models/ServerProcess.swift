import Foundation

struct ServerProcess: Identifiable, Hashable, Codable, Sendable {
    var id: String { "\(pid):\(port)" }
    let pid: Int32
    let pgid: Int32
    let name: String
    let command: String
    let port: UInt16
    var status: SessionStatus
    let discoveredAt: Date

    var localURL: URL? {
        URL(string: "http://localhost:\(port)")
    }

    init(pid: Int32, pgid: Int32, name: String, command: String, port: UInt16, status: SessionStatus = .active) {
        self.pid = pid
        self.pgid = pgid
        self.name = name
        self.command = command
        self.port = port
        self.status = status
        self.discoveredAt = Date()
    }
}
