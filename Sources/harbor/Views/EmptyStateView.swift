import SwiftUI

struct EmptyStateView: View {
    @Environment(\.theme) private var theme
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(0.06))
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(theme.accent.opacity(0.1))
                    .frame(width: 70, height: 70)

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(theme.accentDim)
                    .symbolEffect(.pulse, options: .repeating)
            }
            .offset(y: isAnimating ? -4 : 4)
            .animation(
                .easeInOut(duration: 3).repeatForever(autoreverses: true),
                value: isAnimating
            )

            VStack(spacing: 8) {
                Text("No Active Servers")
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundStyle(theme.textPrimary)

                Text("Listening for dev servers on TCP ports.\nStart one and it will dock here automatically.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { isAnimating = true }
    }
}
