import SwiftUI

struct ProcessRowView: View {
    let process: ServerProcess
    let onTerminate: () -> Void
    let onOpenURL: () -> Void

    @Environment(\.theme) private var theme
    @State private var isHovered = false
    @State private var isTerminateHovered = false
    @State private var isOpenHovered = false
    @State private var confirming = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                StatusIndicatorView(status: process.status)

                VStack(alignment: .leading, spacing: 3) {
                    Text(process.name)
                        .font(.system(size: 13, weight: .semibold, design: .default))
                        .foregroundStyle(
                            process.status == .terminated
                                ? theme.textSecondary
                                : theme.textPrimary
                        )

                    HStack(spacing: 6) {
                        Text(process.command)
                            .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                            .foregroundStyle(theme.textTertiary)

                        Text("·")
                            .foregroundStyle(theme.textTertiary)

                        Text(verbatim: "PID \(process.pid)")
                            .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                            .foregroundStyle(theme.textTertiary)

                        Text("·")
                            .foregroundStyle(theme.textTertiary)

                        portBadge
                    }
                }

                Spacer()

                if process.status == .active {
                    actionButtons
                } else {
                    statusLabel
                }
            }

            if confirming {
                confirmBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    confirming
                        ? theme.danger.opacity(0.06)
                        : isHovered ? theme.surfaceHover : theme.surfaceRaised
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    confirming
                        ? theme.danger.opacity(0.3)
                        : isHovered ? theme.border.opacity(0.8) : theme.border.opacity(0.4),
                    lineWidth: 0.5
                )
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var confirmBar: some View {
        HStack(spacing: 8) {
            Text(verbatim: "Stop \(process.name) on port \(process.port)?")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(1)

            Spacer()

            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) { confirming = false }
            }) {
                Text("Cancel")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(theme.surfaceHover)
                    )
            }
            .buttonStyle(.plain)

            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) { confirming = false }
                onTerminate()
            }) {
                Text("Terminate")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(theme.danger)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 10)
    }

    private var portBadge: some View {
        Text(verbatim: "Port \(process.port)")
            .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
            .foregroundStyle(
                process.status == .active ? theme.accent : theme.textTertiary
            )
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(
                        process.status == .active
                            ? theme.accent.opacity(0.12)
                            : theme.textTertiary.opacity(0.08)
                    )
            )
    }

    private var actionButtons: some View {
        HStack(spacing: 4) {
            Button(action: onOpenURL) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isOpenHovered ? theme.accent : theme.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(isOpenHovered ? theme.accent.opacity(0.12) : .clear)
                    )
            }
            .buttonStyle(.plain)
            .onHover { h in withAnimation(.easeOut(duration: 0.12)) { isOpenHovered = h } }
            .help("Open localhost:\(process.port)")

            Button(action: {
                withAnimation(.easeOut(duration: 0.2)) { confirming = true }
            }) {
                Image(systemName: "stop.circle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(
                        isTerminateHovered ? theme.danger : theme.textSecondary
                    )
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(isTerminateHovered ? theme.danger.opacity(0.12) : .clear)
                    )
            }
            .buttonStyle(.plain)
            .onHover { h in withAnimation(.easeOut(duration: 0.12)) { isTerminateHovered = h } }
            .help("Terminate process")
        }
        .opacity(isHovered ? 1 : 0.5)
    }

    private var statusLabel: some View {
        Text(process.status == .error ? "Error" : "Stopped")
            .font(.system(size: 10.5, weight: .medium, design: .rounded))
            .foregroundStyle(
                process.status == .error ? theme.danger : theme.textTertiary
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(
                        process.status == .error
                            ? theme.danger.opacity(0.1)
                            : theme.textTertiary.opacity(0.08)
                    )
            )
    }
}
