import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

public enum TerminalThemeStyle: String, Codable, Equatable {
    case system
    case os1
    case graphite
    case evergreen
    case dusk
    case paper
    case custom
}

public struct TerminalThemeColor: Codable, Equatable, Hashable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = Self.clamp(red)
        self.green = Self.clamp(green)
        self.blue = Self.clamp(blue)
    }

    public init(hex: Int) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }

    #if canImport(AppKit)
    public init(nsColor: NSColor) {
        let resolved = nsColor.usingColorSpace(.deviceRGB) ?? NSColor.black
        self.init(
            red: Double(resolved.redComponent),
            green: Double(resolved.greenComponent),
            blue: Double(resolved.blueComponent)
        )
    }

    public var nsColor: NSColor {
        NSColor(
            deviceRed: red,
            green: green,
            blue: blue,
            alpha: 1
        )
    }
    #endif

    #if canImport(SwiftUI)
    public var swiftUIColor: Color {
        #if canImport(AppKit)
        return Color(nsColor: nsColor)
        #else
        return Color(red: red, green: green, blue: blue)
        #endif
    }
    #endif

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

public struct TerminalThemePreset: Identifiable, Equatable {
    public let style: TerminalThemeStyle
    public let name: String
    public let summary: String
    public let backgroundColor: TerminalThemeColor
    public let foregroundColor: TerminalThemeColor
    public let ansiPalette: [TerminalThemeColor]

    public var id: String {
        style.rawValue
    }
}

public struct TerminalThemeAppearance: Equatable {
    public let style: TerminalThemeStyle
    public let name: String
    public let backgroundColor: TerminalThemeColor
    public let foregroundColor: TerminalThemeColor
    public let ansiPalette: [TerminalThemeColor]
    public let paletteStyle: TerminalThemeStyle
    public let isCustom: Bool
}

public struct TerminalThemePreference: Codable, Equatable {
    public var style: TerminalThemeStyle = .os1
    public var customBackgroundColor: TerminalThemeColor?
    public var customForegroundColor: TerminalThemeColor?
    public var paletteStyle: TerminalThemeStyle?

    public static let defaultValue = TerminalThemePreference()

    public var resolvedAppearance: TerminalThemeAppearance {
        switch style {
        case .system:
            #if canImport(AppKit)
            return TerminalThemeAppearance(
                style: .system,
                name: "System",
                backgroundColor: TerminalThemeColor(nsColor: NSColor.textBackgroundColor),
                foregroundColor: TerminalThemeColor(nsColor: NSColor.textColor),
                ansiPalette: Self.systemPalette,
                paletteStyle: .system,
                isCustom: false
            )
            #else
            return Self.os1Preset.resolvedAppearance // Fallback on non-AppKit platforms
            #endif
        case .custom:
            let basePreset = Self.preset(for: paletteStyle ?? .os1) ?? Self.os1Preset
            return TerminalThemeAppearance(
                style: .custom,
                name: "Custom",
                backgroundColor: customBackgroundColor ?? basePreset.backgroundColor,
                foregroundColor: customForegroundColor ?? basePreset.foregroundColor,
                ansiPalette: basePreset.ansiPalette,
                paletteStyle: basePreset.style,
                isCustom: true
            )
        case .os1, .graphite, .evergreen, .dusk, .paper:
            let preset = Self.preset(for: style) ?? Self.os1Preset
            return TerminalThemeAppearance(
                style: preset.style,
                name: preset.name,
                backgroundColor: preset.backgroundColor,
                foregroundColor: preset.foregroundColor,
                ansiPalette: preset.ansiPalette,
                paletteStyle: preset.style,
                isCustom: false
            )
        }
    }

    public func selectingPreset(_ style: TerminalThemeStyle) -> TerminalThemePreference {
        TerminalThemePreference(style: style)
    }

    public func updatingBackgroundColor(_ color: TerminalThemeColor) -> TerminalThemePreference {
        let appearance = resolvedAppearance
        return TerminalThemePreference(
            style: .custom,
            customBackgroundColor: color,
            customForegroundColor: appearance.foregroundColor,
            paletteStyle: appearance.paletteStyle
        )
    }

    public func updatingForegroundColor(_ color: TerminalThemeColor) -> TerminalThemePreference {
        let appearance = resolvedAppearance
        return TerminalThemePreference(
            style: .custom,
            customBackgroundColor: appearance.backgroundColor,
            customForegroundColor: color,
            paletteStyle: appearance.paletteStyle
        )
    }

    public static let quickPresets: [TerminalThemePreset] = [
        os1Preset,
        graphitePreset,
        evergreenPreset,
        duskPreset,
        paperPreset
    ]

    private static func preset(for style: TerminalThemeStyle) -> TerminalThemePreset? {
        quickPresets.first(where: { $0.style == style })
    }

    private static let os1Preset = TerminalThemePreset(
        style: .os1,
        name: "OS1",
        summary: "Coral surface with cream text.",
        backgroundColor: TerminalThemeColor(hex: 0xA84832),
        foregroundColor: TerminalThemeColor(hex: 0xF5EBE0),
        ansiPalette: palette([
            0x2A1810, 0xE6745A, 0x9CC089, 0xE6CB94,
            0x9DBED9, 0xC4A4DC, 0x9ACECE, 0xF0E5D4,
            0x4A2820, 0xF08C7A, 0xB8D5A8, 0xF2DBA8,
            0xB6CFE5, 0xD3BBE6, 0xB8DBDB, 0xFFFAF0
        ])
    )

    private static let graphitePreset = TerminalThemePreset(
        style: .graphite,
        name: "Graphite",
        summary: "Neutral dark theme.",
        backgroundColor: TerminalThemeColor(hex: 0x12161D),
        foregroundColor: TerminalThemeColor(hex: 0xE7ECF3),
        ansiPalette: palette([
            0x1F2430, 0xC7746E, 0x88B976, 0xD6B97A,
            0x78A6D8, 0xB18AD0, 0x6EC5C8, 0xCFD6E3,
            0x596273, 0xE08D86, 0x9FD58A, 0xE4CA91,
            0x93B8E4, 0xC7A3E1, 0x8BD9DA, 0xF4F7FB
        ])
    )

    private static let evergreenPreset = TerminalThemePreset(
        style: .evergreen,
        name: "Evergreen",
        summary: "Deep forest backdrop.",
        backgroundColor: TerminalThemeColor(hex: 0x0F1714),
        foregroundColor: TerminalThemeColor(hex: 0xDBE8E1),
        ansiPalette: palette([
            0x16211D, 0xC97973, 0x73B181, 0xD5B66A,
            0x6D98C4, 0xAA86BF, 0x63BEB0, 0xC6D5CE,
            0x4F635B, 0xE49790, 0x8ED09D, 0xE9CB88,
            0x8CB4D6, 0xC39BD3, 0x7FD6C8, 0xEFF7F3
        ])
    )

    private static let duskPreset = TerminalThemePreset(
        style: .dusk,
        name: "Dusk",
        summary: "Cool navy tones.",
        backgroundColor: TerminalThemeColor(hex: 0x101726),
        foregroundColor: TerminalThemeColor(hex: 0xDDE7F7),
        ansiPalette: palette([
            0x1A2235, 0xD06E79, 0x86B97B, 0xD5BA79,
            0x7AA2D8, 0xB390D2, 0x70C0D0, 0xCCD7EA,
            0x55627E, 0xE48A95, 0xA1D191, 0xE6CD90,
            0x97B9E8, 0xC9A5E3, 0x89D9E4, 0xF4F8FD
        ])
    )

    private static let paperPreset = TerminalThemePreset(
        style: .paper,
        name: "Paper",
        summary: "Light, editorial theme.",
        backgroundColor: TerminalThemeColor(hex: 0xF5F1E8),
        foregroundColor: TerminalThemeColor(hex: 0x2F3743),
        ansiPalette: palette([
            0x3C4657, 0xB44A56, 0x4E8B67, 0xA77720,
            0x416EA9, 0x8758A6, 0x2E8B92, 0xD9D2C4,
            0x6D7482, 0xCD6571, 0x66A07C, 0xBF9147,
            0x5C86BE, 0xA072BD, 0x53A6AD, 0xFFFDF8
        ])
    )

    private static let systemPalette = palette([
        0x000000, 0xC23621, 0x25BC24, 0xADAD27,
        0x492EE1, 0xD338D3, 0x33BBC8, 0xCBCCCD,
        0x818383, 0xFC391F, 0x31E722, 0xEAEC23,
        0x5833FF, 0xF935F8, 0x14F0F0, 0xE9EBEB
    ])

    private static func palette(_ hexValues: [Int]) -> [TerminalThemeColor] {
        hexValues.map(TerminalThemeColor.init(hex:))
    }
}

extension TerminalThemePreset {
    public var resolvedAppearance: TerminalThemeAppearance {
        TerminalThemeAppearance(
            style: style,
            name: name,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            ansiPalette: ansiPalette,
            paletteStyle: style,
            isCustom: false
        )
    }
}
