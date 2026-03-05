import SwiftUI

struct StatusIndicatorView: View {
    let status: SessionStatus

    @Environment(\.theme) private var theme
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            if status == .active {
                Circle()
                    .fill(theme.accent.opacity(0.3))
                    .frame(width: 18, height: 18)
                    .scaleEffect(isPulsing ? 1.4 : 1.0)
                    .opacity(isPulsing ? 0.0 : 0.6)
            }

            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            Circle()
                .fill(statusColor.opacity(0.6))
                .frame(width: 10, height: 10)
                .blur(radius: 4)
        }
        .frame(width: 22, height: 22)
        .onAppear {
            guard status == .active else { return }
            withAnimation(
                .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
    }

    private var statusColor: Color {
        switch status {
        case .active: theme.accent
        case .error: theme.danger
        case .terminated: theme.terminated
        }
    }
}
