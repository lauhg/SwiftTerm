//
//  TerminalContrastCorrection.swift
//
//  Created by Mossh.
//

import Foundation

public enum TerminalColorScheme: Equatable {
    case dark
    case light
}

public struct TerminalThemePalette: Equatable {
    public var background: Color
    public var foreground: Color
    public var ansiColors: [Color]

    public static let fallback = TerminalThemePalette(
        background: Color(red: 0, green: 0, blue: 0),
        foreground: Color(red: 65535, green: 65535, blue: 65535),
        ansiColors: []
    )

    public init(background: Color, foreground: Color, ansiColors: [Color]) {
        self.background = background
        self.foreground = foreground
        self.ansiColors = ansiColors
    }
}

public struct TerminalContrastCorrection: Equatable {
    public var isEnabled: Bool
    public var localColorScheme: TerminalColorScheme
    public var localPalette: TerminalThemePalette
    public var minimumContrastRatio: Double
    public var darkBackgroundThreshold: Double
    public var lightBackgroundThreshold: Double
    public var harmonizeReadableNeutralExtremes: Bool
    public var harmonizeReadablePastelAccents: Bool

    public static let disabled = TerminalContrastCorrection(isEnabled: false)

    public init(
        isEnabled: Bool = false,
        localColorScheme: TerminalColorScheme = .dark,
        localPalette: TerminalThemePalette = .fallback,
        minimumContrastRatio: Double = 4.5,
        darkBackgroundThreshold: Double = 0.28,
        lightBackgroundThreshold: Double = 0.72,
        harmonizeReadableNeutralExtremes: Bool = false,
        harmonizeReadablePastelAccents: Bool = false
    ) {
        self.isEnabled = isEnabled
        self.localColorScheme = localColorScheme
        self.localPalette = localPalette
        self.minimumContrastRatio = minimumContrastRatio
        self.darkBackgroundThreshold = darkBackgroundThreshold
        self.lightBackgroundThreshold = lightBackgroundThreshold
        self.harmonizeReadableNeutralExtremes = harmonizeReadableNeutralExtremes
        self.harmonizeReadablePastelAccents = harmonizeReadablePastelAccents
    }

    func correctedPair(
        foreground: TerminalSRGBColor,
        background: TerminalSRGBColor,
        underline: TerminalSRGBColor? = nil,
        hasExplicitForeground: Bool,
        hasExplicitUnderline: Bool = false,
        backgroundRole: TerminalBackgroundRole,
        isInverse: Bool = false
    ) -> TerminalColorPair? {
        guard let mode = correctionMode(
            foreground: foreground,
            background: background,
            backgroundRole: backgroundRole,
            isInverse: isInverse
        ) else {
            return nil
        }

        let correctedBackground = themedBackground(for: background, mode: mode)
        let correctedForeground = themedForeground(
            for: foreground,
            on: correctedBackground,
            hasExplicitForeground: hasExplicitForeground
        )
        let correctedUnderline = underline.map {
            themedForeground(
                for: $0,
                on: correctedBackground,
                hasExplicitForeground: hasExplicitUnderline
            )
        }
        return TerminalColorPair(
            foreground: correctedForeground,
            background: correctedBackground,
            underline: correctedUnderline
        )
    }

    func backgroundRole(
        originalAttribute _: Attribute,
        resolvedBackgroundAttribute: Attribute.Color,
        resolvedBackground: TerminalSRGBColor
    ) -> TerminalBackgroundRole {
        switch resolvedBackgroundAttribute {
        case .defaultColor:
            return .defaultBackground
        case .defaultInvertedColor:
            return .invertedDefaultSurface
        case .trueColor:
            return .remoteExplicit
        case .ansi256(let code):
            if code < 16 {
                return isThemeAnsiColor(resolvedBackground, index: Int(code)) ? .themeAnsi : .remoteExplicit
            }
            return .remoteExplicit
        }
    }

    func isThemeAnsiColor(_ color: TerminalSRGBColor, index: Int) -> Bool {
        guard localPalette.ansiColors.indices.contains(index) else {
            return true
        }
        let themeColor = TerminalSRGBColor(localPalette.ansiColors[index])
        return color.maximumChannelDistance(to: themeColor) <= (2.0 / 255.0)
    }

    private func correctionMode(
        foreground: TerminalSRGBColor,
        background: TerminalSRGBColor,
        backgroundRole: TerminalBackgroundRole,
        isInverse: Bool
    ) -> TerminalCorrectionMode? {
        guard isEnabled,
              let remoteColorScheme = remoteColorScheme(for: background),
              remoteColorScheme != localColorScheme else {
            return nil
        }

        if backgroundRole == .remoteExplicit,
           foreground.contrastRatio(with: background) < minimumContrastRatio {
            return .readability
        }

        if shouldHarmonizeReadableNeutralExtreme(background: background, backgroundRole: backgroundRole) {
            return .neutralExtremeSurface
        }

        if shouldHarmonizeReadablePastelAccent(
            background: background,
            backgroundRole: backgroundRole,
            isInverse: isInverse
        ) {
            return .pastelAccentSurface
        }

        return nil
    }

    private func shouldHarmonizeReadableNeutralExtreme(
        background: TerminalSRGBColor,
        backgroundRole: TerminalBackgroundRole
    ) -> Bool {
        guard harmonizeReadableNeutralExtremes,
              backgroundRole == .remoteExplicit || backgroundRole == .invertedDefaultSurface else {
            return false
        }

        let backgroundLab = TerminalOklabColor(background)
        guard backgroundLab.chroma <= 0.04 else {
            return false
        }

        guard isOppositeExtreme(backgroundLab) else {
            return false
        }

        let localBackground = TerminalSRGBColor(localPalette.background)
        return background.contrastRatio(with: localBackground) >= 10.0
    }

    private func shouldHarmonizeReadablePastelAccent(
        background: TerminalSRGBColor,
        backgroundRole: TerminalBackgroundRole,
        isInverse: Bool
    ) -> Bool {
        guard harmonizeReadablePastelAccents,
              backgroundRole == .remoteExplicit,
              !isInverse else {
            return false
        }

        let backgroundLab = TerminalOklabColor(background)
        guard (0.025...0.16).contains(backgroundLab.chroma),
              isOppositePastel(backgroundLab),
              closestThemeAccent(to: background, maximumHueDistance: 35.0) != nil else {
            return false
        }

        let localBackground = TerminalSRGBColor(localPalette.background)
        return background.contrastRatio(with: localBackground) >= 10.0
    }

    private func isOppositeExtreme(_ color: TerminalOklabColor) -> Bool {
        switch localColorScheme {
        case .dark:
            return color.lightness >= 0.94
        case .light:
            return color.lightness <= 0.30
        }
    }

    private func isOppositePastel(_ color: TerminalOklabColor) -> Bool {
        switch localColorScheme {
        case .dark:
            return color.lightness >= 0.90
        case .light:
            return color.lightness <= 0.45
        }
    }

    private func themedBackground(
        for remoteBackground: TerminalSRGBColor,
        mode: TerminalCorrectionMode
    ) -> TerminalSRGBColor {
        let localBackground = TerminalSRGBColor(localPalette.background)
        let localForeground = TerminalSRGBColor(localPalette.foreground)
        let localBackgroundLab = TerminalOklabColor(localBackground)
        let localForegroundLab = TerminalOklabColor(localForeground)

        var surface = localBackgroundLab.mixed(
            with: localForegroundLab,
            amount: localColorScheme == .dark ? 0.14 : 0.10
        )

        if mode.usesAccent,
           let accent = closestThemeAccent(to: remoteBackground) {
            surface = surface.mixed(
                with: TerminalOklabColor(accent),
                amount: localColorScheme == .dark ? 0.18 : 0.12
            )
        }

        let constrainedLightness = surfaceLightness(
            surface.lightness,
            localBackgroundLightness: localBackgroundLab.lightness
        )
        return surface.withLightness(constrainedLightness).toSRGBGamutMapped()
    }

    private func themedForeground(
        for remoteForeground: TerminalSRGBColor,
        on background: TerminalSRGBColor,
        hasExplicitForeground: Bool
    ) -> TerminalSRGBColor {
        var foreground = TerminalSRGBColor(localPalette.foreground)

        if hasExplicitForeground,
           TerminalOklabColor(remoteForeground).chroma >= 0.035,
           let accent = closestThemeAccent(to: remoteForeground) {
            foreground = accent
        }

        return readableColor(foreground, on: background)
    }

    private func readableColor(_ color: TerminalSRGBColor, on background: TerminalSRGBColor) -> TerminalSRGBColor {
        if color.contrastRatio(with: background) >= minimumContrastRatio {
            return color
        }
        if let adjusted = colorByAdjustingLightness(of: color, on: background) {
            return adjusted
        }

        let localForeground = TerminalSRGBColor(localPalette.foreground)
        if localForeground.contrastRatio(with: background) >= minimumContrastRatio {
            return localForeground
        }

        let blackContrast = TerminalSRGBColor.black.contrastRatio(with: background)
        let whiteContrast = TerminalSRGBColor.white.contrastRatio(with: background)
        return blackContrast >= whiteContrast ? .black : .white
    }

    private func colorByAdjustingLightness(
        of color: TerminalSRGBColor,
        on background: TerminalSRGBColor
    ) -> TerminalSRGBColor? {
        let backgroundLightness = TerminalOklabColor(background).lightness
        let source = TerminalOklabColor(color)
        let makeLightText = localColorScheme == .dark
        var low = 0.0
        var high = 1.0
        var best: TerminalSRGBColor?

        if makeLightText {
            low = max(source.lightness, backgroundLightness)
        } else {
            high = min(source.lightness, backgroundLightness)
        }

        for _ in 0..<28 {
            let mid = (low + high) * 0.5
            let candidate = source.withLightness(mid).toSRGBGamutMapped()
            if candidate.contrastRatio(with: background) >= minimumContrastRatio {
                best = candidate
                if makeLightText {
                    high = mid
                } else {
                    low = mid
                }
            } else if makeLightText {
                low = mid
            } else {
                high = mid
            }
        }

        return best
    }

    private func closestThemeAccent(
        to color: TerminalSRGBColor,
        maximumHueDistance: Double? = nil
    ) -> TerminalSRGBColor? {
        let source = TerminalOklabColor(color)
        guard source.chroma >= 0.025 else {
            return nil
        }

        let indexedAccents = localPalette.ansiColors.enumerated().filter { index, _ in
            (1...6).contains(index) || (9...14).contains(index)
        }
        let accentColors = indexedAccents.isEmpty ? localPalette.ansiColors : indexedAccents.map(\.element)

        let candidates = accentColors
            .map(TerminalSRGBColor.init)
            .filter { TerminalOklabColor($0).chroma >= 0.025 }
            .map { accent in
                (accent, source.distanceToHue(of: TerminalOklabColor(accent)))
            }
        guard let closest = candidates.min(by: { $0.1 < $1.1 }) else {
            return nil
        }
        if let maximumHueDistance,
           closest.1 > maximumHueDistance {
            return nil
        }
        return closest.0
    }

    private func surfaceLightness(_ lightness: Double, localBackgroundLightness: Double) -> Double {
        if localColorScheme == .dark {
            let lower = min(localBackgroundLightness + 0.07, 0.88)
            let upper = min(localBackgroundLightness + 0.20, 0.92)
            return min(max(lightness, lower), max(lower, upper))
        } else {
            let lower = max(localBackgroundLightness - 0.20, 0.08)
            let upper = max(localBackgroundLightness - 0.05, 0.12)
            return min(max(lightness, min(lower, upper)), upper)
        }
    }

    private func remoteColorScheme(for color: TerminalSRGBColor) -> TerminalColorScheme? {
        let luminance = color.relativeLuminance
        if luminance <= darkBackgroundThreshold {
            return .dark
        }
        if luminance >= lightBackgroundThreshold {
            return .light
        }
        return nil
    }
}

struct TerminalColorPair: Equatable {
    let foreground: TerminalSRGBColor
    let background: TerminalSRGBColor
    let underline: TerminalSRGBColor?
}

enum TerminalBackgroundRole: Equatable {
    case defaultBackground
    case themeAnsi
    case remoteExplicit
    case invertedDefaultSurface
}

private enum TerminalCorrectionMode {
    case readability
    case neutralExtremeSurface
    case pastelAccentSurface

    var usesAccent: Bool {
        switch self {
        case .readability, .pastelAccentSurface:
            return true
        case .neutralExtremeSurface:
            return false
        }
    }
}

struct TerminalSRGBColor: Equatable {
    let red: Double
    let green: Double
    let blue: Double

    static let black = TerminalSRGBColor(red: 0, green: 0, blue: 0)
    static let white = TerminalSRGBColor(red: 1, green: 1, blue: 1)

    init(red: Double, green: Double, blue: Double) {
        self.red = min(max(red, 0), 1)
        self.green = min(max(green, 0), 1)
        self.blue = min(max(blue, 0), 1)
    }

    init(_ color: Color) {
        self.init(
            red: Double(color.red) / 65535.0,
            green: Double(color.green) / 65535.0,
            blue: Double(color.blue) / 65535.0
        )
    }

    var relativeLuminance: Double {
        0.2126 * Self.linearized(red) +
            0.7152 * Self.linearized(green) +
            0.0722 * Self.linearized(blue)
    }

    func contrastRatio(with other: TerminalSRGBColor) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    func maximumChannelDistance(to other: TerminalSRGBColor) -> Double {
        max(abs(red - other.red), abs(green - other.green), abs(blue - other.blue))
    }

    private static func linearized(_ value: Double) -> Double {
        if value <= 0.03928 {
            return value / 12.92
        }
        return pow((value + 0.055) / 1.055, 2.4)
    }
}

private struct TerminalOklabColor {
    let lightness: Double
    let a: Double
    let b: Double

    init(lightness: Double, a: Double, b: Double) {
        self.lightness = min(max(lightness, 0), 1)
        self.a = a
        self.b = b
    }

    init(_ color: TerminalSRGBColor) {
        let red = Self.srgbToLinear(color.red)
        let green = Self.srgbToLinear(color.green)
        let blue = Self.srgbToLinear(color.blue)

        let l = 0.4122214708 * red + 0.5363325363 * green + 0.0514459929 * blue
        let m = 0.2119034982 * red + 0.6806995451 * green + 0.1073969566 * blue
        let s = 0.0883024619 * red + 0.2817188376 * green + 0.6299787005 * blue

        let lRoot = pow(max(l, 0), 1.0 / 3.0)
        let mRoot = pow(max(m, 0), 1.0 / 3.0)
        let sRoot = pow(max(s, 0), 1.0 / 3.0)

        lightness = 0.2104542553 * lRoot + 0.7936177850 * mRoot - 0.0040720468 * sRoot
        a = 1.9779984951 * lRoot - 2.4285922050 * mRoot + 0.4505937099 * sRoot
        b = 0.0259040371 * lRoot + 0.7827717662 * mRoot - 0.8086757660 * sRoot
    }

    var chroma: Double {
        sqrt(a * a + b * b)
    }

    var hue: Double? {
        guard chroma > 0.000004 else {
            return nil
        }
        let angle = atan2(b, a) * 180.0 / Double.pi
        return angle >= 0 ? angle : angle + 360.0
    }

    func mixed(with other: TerminalOklabColor, amount: Double) -> TerminalOklabColor {
        let amount = min(max(amount, 0), 1)
        return TerminalOklabColor(
            lightness: lightness + (other.lightness - lightness) * amount,
            a: a + (other.a - a) * amount,
            b: b + (other.b - b) * amount
        )
    }

    func withLightness(_ lightness: Double) -> TerminalOklabColor {
        TerminalOklabColor(lightness: lightness, a: a, b: b)
    }

    func withChromaScale(_ scale: Double) -> TerminalOklabColor {
        TerminalOklabColor(lightness: lightness, a: a * scale, b: b * scale)
    }

    func distanceToHue(of other: TerminalOklabColor) -> Double {
        guard let hue, let otherHue = other.hue else {
            return Double.greatestFiniteMagnitude
        }
        let direct = abs(hue - otherHue)
        return min(direct, 360.0 - direct)
    }

    func toSRGBGamutMapped() -> TerminalSRGBColor {
        if let color = convertedIfInGamut() {
            return color
        }

        var low = 0.0
        var high = 1.0
        var best = withChromaScale(0).convertedClamped()
        for _ in 0..<24 {
            let mid = (low + high) * 0.5
            let candidate = withChromaScale(mid)
            if let color = candidate.convertedIfInGamut() {
                best = color
                low = mid
            } else {
                high = mid
            }
        }
        return best
    }

    private func convertedIfInGamut() -> TerminalSRGBColor? {
        let rgb = linearSRGB()
        guard rgb.red.isFinite, rgb.green.isFinite, rgb.blue.isFinite,
              (0...1).contains(rgb.red),
              (0...1).contains(rgb.green),
              (0...1).contains(rgb.blue) else {
            return nil
        }
        return TerminalSRGBColor(
            red: Self.linearToSRGB(rgb.red),
            green: Self.linearToSRGB(rgb.green),
            blue: Self.linearToSRGB(rgb.blue)
        )
    }

    private func convertedClamped() -> TerminalSRGBColor {
        let rgb = linearSRGB()
        return TerminalSRGBColor(
            red: Self.linearToSRGB(min(max(rgb.red, 0), 1)),
            green: Self.linearToSRGB(min(max(rgb.green, 0), 1)),
            blue: Self.linearToSRGB(min(max(rgb.blue, 0), 1))
        )
    }

    private func linearSRGB() -> (red: Double, green: Double, blue: Double) {
        let lRoot = lightness + 0.3963377774 * a + 0.2158037573 * b
        let mRoot = lightness - 0.1055613458 * a - 0.0638541728 * b
        let sRoot = lightness - 0.0894841775 * a - 1.2914855480 * b

        let l = lRoot * lRoot * lRoot
        let m = mRoot * mRoot * mRoot
        let s = sRoot * sRoot * sRoot

        return (
            4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
        )
    }

    private static func srgbToLinear(_ value: Double) -> Double {
        if value <= 0.04045 {
            return value / 12.92
        }
        return pow((value + 0.055) / 1.055, 2.4)
    }

    private static func linearToSRGB(_ value: Double) -> Double {
        if value <= 0.0031308 {
            return value * 12.92
        }
        return 1.055 * pow(value, 1.0 / 2.4) - 0.055
    }
}
