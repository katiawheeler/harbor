import SwiftUI
import Observation

enum ThemeMode: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark
}

@MainActor @Observable
final class ThemeSettings {
    var mode: ThemeMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: "harbor.themeMode") }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: "harbor.themeMode"),
           let saved = ThemeMode(rawValue: raw) {
            self.mode = saved
        } else {
            self.mode = .system
        }
    }

    private var systemIsDark: Bool {
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    var resolvedIsDark: Bool {
        switch mode {
        case .system: systemIsDark
        case .dark: true
        case .light: false
        }
    }

    var colors: HarborColors {
        resolvedIsDark ? .dark : .light
    }
}

struct HarborColors: Sendable {
    let accent: Color
    let accentDim: Color
    let danger: Color
    let dangerDim: Color
    let warning: Color
    let surface: Color
    let surfaceRaised: Color
    let surfaceHover: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let border: Color
    let terminated: Color

    static let dark = HarborColors(
        accent: Color(red: 0.2, green: 0.78, blue: 0.76),
        accentDim: Color(red: 0.15, green: 0.55, blue: 0.54),
        danger: Color(red: 0.95, green: 0.35, blue: 0.38),
        dangerDim: Color(red: 0.7, green: 0.25, blue: 0.28),
        warning: Color(red: 0.95, green: 0.7, blue: 0.25),
        surface: Color(white: 0.08),
        surfaceRaised: Color(white: 0.12),
        surfaceHover: Color(white: 0.15),
        textPrimary: Color(white: 0.92),
        textSecondary: Color(white: 0.52),
        textTertiary: Color(white: 0.35),
        border: Color(white: 0.16),
        terminated: Color(white: 0.4)
    )

    static let light = HarborColors(
        accent: Color(red: 0.02, green: 0.52, blue: 0.50),
        accentDim: Color(red: 0.02, green: 0.42, blue: 0.40),
        danger: Color(red: 0.82, green: 0.18, blue: 0.22),
        dangerDim: Color(red: 0.65, green: 0.12, blue: 0.16),
        warning: Color(red: 0.78, green: 0.52, blue: 0.04),
        surface: Color(red: 0.95, green: 0.94, blue: 0.92),
        surfaceRaised: Color(red: 0.99, green: 0.98, blue: 0.97),
        surfaceHover: Color(red: 0.92, green: 0.91, blue: 0.89),
        textPrimary: Color(red: 0.1, green: 0.12, blue: 0.13),
        textSecondary: Color(red: 0.35, green: 0.40, blue: 0.44),
        textTertiary: Color(red: 0.54, green: 0.58, blue: 0.62),
        border: Color(red: 0.83, green: 0.82, blue: 0.80),
        terminated: Color(red: 0.62, green: 0.65, blue: 0.68)
    )
}

struct ThemeKey: EnvironmentKey {
    static let defaultValue = HarborColors.dark
}

extension EnvironmentValues {
    var theme: HarborColors {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
