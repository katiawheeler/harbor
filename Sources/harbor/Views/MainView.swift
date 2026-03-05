import SwiftUI

struct MainView: View {
    @State private var viewModel = ProcessMonitorViewModel()
    @State private var searchText = ""
    @Environment(ThemeSettings.self) private var themeSettings

    private var theme: HarborColors { themeSettings.colors }

    private var filteredProcesses: [ServerProcess] {
        guard !searchText.isEmpty else { return viewModel.processes }
        let query = searchText.lowercased()
        return viewModel.processes.filter { process in
            process.name.lowercased().contains(query)
                || String(process.port).contains(query)
                || String(process.pid).contains(query)
        }
    }

    private var themeIcon: String {
        switch themeSettings.mode {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }

    private var themeTooltip: String {
        switch themeSettings.mode {
        case .system: "Theme: System (click to switch)"
        case .light: "Theme: Light (click to switch)"
        case .dark: "Theme: Dark (click to switch)"
        }
    }

    private var activeCount: Int {
        viewModel.processes.filter { $0.status == .active }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(theme.border)

            if !viewModel.hasCompletedInitialLoad {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.processes.isEmpty {
                EmptyStateView()
            } else {
                processListContent
            }

            if let error = viewModel.errorMessage {
                errorBanner(error)
            }
        }
        .background(theme.surface)
        .environment(\.theme, themeSettings.colors)
        .task {
            viewModel.startMonitoring()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Harbor")
                    .font(.system(size: 15, weight: .bold, design: .default))
                    .foregroundStyle(theme.textPrimary)

                HStack(spacing: 6) {
                    Circle()
                        .fill(activeCount > 0 ? theme.accent : theme.textTertiary)
                        .frame(width: 6, height: 6)

                    Text(
                        activeCount > 0
                            ? "\(activeCount) active server\(activeCount == 1 ? "" : "s")"
                            : "No active servers"
                    )
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(theme.textTertiary)

                TextField("Filter", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundStyle(theme.textPrimary)
                    .frame(width: 100)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(theme.surfaceRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(theme.border.opacity(0.5), lineWidth: 0.5)
            )

            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    switch themeSettings.mode {
                    case .system: themeSettings.mode = .light
                    case .light: themeSettings.mode = .dark
                    case .dark: themeSettings.mode = .system
                    }
                }
            }) {
                Image(systemName: themeIcon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(theme.surfaceRaised)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(theme.border.opacity(0.5), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
            .help(themeTooltip)

            Button(action: { Task { await viewModel.refresh() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(theme.surfaceRaised)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(theme.border.opacity(0.5), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
            .help("Refresh")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var processListContent: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(filteredProcesses) { process in
                    ProcessRowView(
                        process: process,
                        onTerminate: {
                            withAnimation(.easeOut(duration: 0.25)) {
                                viewModel.terminateProcess(process)
                            }
                        },
                        onOpenURL: { viewModel.openInBrowser(process) }
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .animation(.easeInOut(duration: 0.3), value: filteredProcesses.map(\.id))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(theme.warning)

            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(1)

            Spacer()

            Button(action: { viewModel.errorMessage = nil }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(theme.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(theme.warning.opacity(0.08))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
