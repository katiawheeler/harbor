import Foundation

struct ProcessTerminationService: Sendable {
    enum TerminationError: Error, LocalizedError {
        case permissionDenied(pid: Int32)
        case processNotFound(pid: Int32)
        case unexpectedError(Int32)

        var errorDescription: String? {
            switch self {
            case .permissionDenied(let pid):
                "Permission denied terminating PID \(pid). Process may be owned by another user."
            case .processNotFound(let pid):
                "Process \(pid) not found — it may have already exited."
            case .unexpectedError(let code):
                "Failed to terminate process (errno: \(code))"
            }
        }
    }

    func terminate(pid: Int32, forceful: Bool = false) throws {
        let signal: Int32 = forceful ? SIGKILL : SIGTERM
        let result = kill(pid, signal)
        guard result != 0 else { return }

        switch errno {
        case EPERM:
            throw TerminationError.permissionDenied(pid: pid)
        case ESRCH:
            throw TerminationError.processNotFound(pid: pid)
        default:
            throw TerminationError.unexpectedError(errno)
        }
    }
}
