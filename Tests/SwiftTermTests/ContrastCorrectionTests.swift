//
//  ContrastCorrectionTests.swift
//
//  Created by Mossh.
//

import Testing
@testable import SwiftTerm

struct ContrastCorrectionTests {
    @Test func lightRemoteSurfaceOnDarkLocalUsesThemeSurface() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.mosshDarkPalette
        )

        let pair = correction.correctedPair(
            foreground: Self.srgb(0xf7f7f7),
            background: Self.srgb(0xffffff),
            hasExplicitForeground: false,
            backgroundRole: .remoteExplicit
        )

        #expect(pair != nil)
        guard let pair else {
            return
        }
        #expect(pair.foreground.contrastRatio(with: pair.background) >= 4.5)
        #expect(pair.foreground != .black)
        #expect(pair.background != .white)
        #expect(pair.background.relativeLuminance < Self.srgb(0xffffff).relativeLuminance)
        #expect(pair.background.relativeLuminance > Self.srgb(0x0a0d10).relativeLuminance)
    }

    @Test func darkRemoteSurfaceOnLightLocalUsesThemeSurface() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .light,
            localPalette: Self.solarizedLightPalette
        )

        let pair = correction.correctedPair(
            foreground: Self.srgb(0x101010),
            background: Self.srgb(0x000000),
            hasExplicitForeground: false,
            backgroundRole: .remoteExplicit
        )

        #expect(pair != nil)
        guard let pair else {
            return
        }
        #expect(pair.foreground.contrastRatio(with: pair.background) >= 4.5)
        #expect(pair.foreground != .white)
        #expect(pair.background != .black)
        #expect(pair.background.relativeLuminance > Self.srgb(0x000000).relativeLuminance)
        #expect(pair.background.relativeLuminance < Self.srgb(0xfdf6e3).relativeLuminance)
    }

    @Test func explicitColoredForegroundUsesNearestThemeAccent() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.draculaPalette
        )

        let pair = correction.correctedPair(
            foreground: Self.srgb(0xffff00),
            background: Self.srgb(0xffffff),
            hasExplicitForeground: true,
            backgroundRole: .remoteExplicit
        )

        #expect(pair != nil)
        guard let pair else {
            return
        }
        #expect(pair.foreground.contrastRatio(with: pair.background) >= 4.5)
        #expect(pair.foreground != .black)
        #expect(pair.background != .white)
    }

    @Test func matchingColorSchemesDoNotCorrect() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .light,
            localPalette: Self.solarizedLightPalette
        )

        let pair = correction.correctedPair(
            foreground: Self.srgb(0xf7f7f7),
            background: Self.srgb(0xffffff),
            hasExplicitForeground: false,
            backgroundRole: .remoteExplicit
        )

        #expect(pair == nil)
    }

    @Test func sufficientContrastDoesNotCorrect() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.mosshDarkPalette
        )

        let pair = correction.correctedPair(
            foreground: .black,
            background: Self.srgb(0xffffff),
            hasExplicitForeground: true,
            backgroundRole: .remoteExplicit
        )

        #expect(pair == nil)
    }

    @Test func readableNeutralExtremeOnDarkLocalUsesThemeSurfaceWhenEnabled() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.mosshDarkPalette,
            harmonizeReadableNeutralExtremes: true
        )

        let pair = correction.correctedPair(
            foreground: .black,
            background: .white,
            hasExplicitForeground: true,
            backgroundRole: .remoteExplicit
        )

        #expect(pair != nil)
        guard let pair else {
            return
        }
        #expect(pair.foreground.contrastRatio(with: pair.background) >= 4.5)
        #expect(pair.foreground != .black)
        #expect(pair.background != .white)
        #expect(pair.background.relativeLuminance < Self.srgb(0xffffff).relativeLuminance)
        #expect(pair.background.relativeLuminance > Self.srgb(0x0a0d10).relativeLuminance)
    }

    @Test func ansi255NeutralExtremeOnDarkLocalUsesThemeSurface() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.mosshDarkPalette,
            harmonizeReadableNeutralExtremes: true
        )
        let attribute = Attribute(fg: .ansi256(code: 235), bg: .ansi256(code: 255), style: .none)
        let background = Self.srgb(0xeeeeee)
        let role = correction.backgroundRole(
            originalAttribute: attribute,
            resolvedBackgroundAttribute: .ansi256(code: 255),
            resolvedBackground: background
        )

        #expect(role == .remoteExplicit)
        let pair = correction.correctedPair(
            foreground: Self.srgb(0x262626),
            background: background,
            hasExplicitForeground: true,
            backgroundRole: role
        )

        #expect(pair != nil)
        guard let pair else {
            return
        }
        #expect(pair.foreground.contrastRatio(with: pair.background) >= 4.5)
        #expect(pair.background != background)
        #expect(pair.background.relativeLuminance < background.relativeLuminance)
        #expect(pair.background.relativeLuminance > Self.srgb(0x0a0d10).relativeLuminance)
    }

    @Test func readableNeutralExtremeOnLightLocalUsesThemeSurfaceWhenEnabled() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .light,
            localPalette: Self.solarizedLightPalette,
            harmonizeReadableNeutralExtremes: true
        )

        let pair = correction.correctedPair(
            foreground: .white,
            background: .black,
            hasExplicitForeground: true,
            backgroundRole: .remoteExplicit
        )

        #expect(pair != nil)
        guard let pair else {
            return
        }
        #expect(pair.foreground.contrastRatio(with: pair.background) >= 4.5)
        #expect(pair.foreground != .white)
        #expect(pair.background != .black)
        #expect(pair.background.relativeLuminance > Self.srgb(0x000000).relativeLuminance)
        #expect(pair.background.relativeLuminance < Self.srgb(0xfdf6e3).relativeLuminance)
    }

    @Test func coloredReadableBackgroundsDoNotHarmonize() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.mosshDarkPalette,
            harmonizeReadableNeutralExtremes: true
        )

        let greenPair = correction.correctedPair(
            foreground: .black,
            background: Self.srgb(0xddffdd),
            hasExplicitForeground: true,
            backgroundRole: .remoteExplicit
        )
        let yellowPair = correction.correctedPair(
            foreground: .black,
            background: Self.srgb(0xffe58a),
            hasExplicitForeground: true,
            backgroundRole: .remoteExplicit
        )

        #expect(greenPair == nil)
        #expect(yellowPair == nil)
    }

    @Test func invertedDefaultNeutralExtremeHarmonizes() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.mosshDarkPalette,
            harmonizeReadableNeutralExtremes: true
        )

        let pair = correction.correctedPair(
            foreground: .black,
            background: .white,
            hasExplicitForeground: true,
            backgroundRole: .invertedDefaultSurface,
            isInverse: true
        )

        #expect(pair != nil)
        guard let pair else {
            return
        }
        #expect(pair.foreground.contrastRatio(with: pair.background) >= 4.5)
        #expect(pair.background != .white)
    }

    @Test func defaultBackgroundsDoNotCorrect() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.mosshDarkPalette,
            harmonizeReadableNeutralExtremes: true
        )

        let pair = correction.correctedPair(
            foreground: Self.srgb(0xf7f7f7),
            background: Self.srgb(0xffffff),
            hasExplicitForeground: false,
            backgroundRole: .defaultBackground
        )

        #expect(pair == nil)
    }

    @Test func nonExtremeNeutralBackgroundsDoNotHarmonize() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.mosshDarkPalette,
            harmonizeReadableNeutralExtremes: true
        )

        let pair = correction.correctedPair(
            foreground: .black,
            background: Self.srgb(0xe0e0e0),
            hasExplicitForeground: true,
            backgroundRole: .remoteExplicit
        )

        #expect(pair == nil)
    }

    @Test func middleLuminanceBackgroundsDoNotCorrect() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.mosshDarkPalette
        )

        let pair = correction.correctedPair(
            foreground: Self.srgb(0xa6a6a6),
            background: Self.srgb(0x9e9e9e),
            hasExplicitForeground: false,
            backgroundRole: .remoteExplicit
        )

        #expect(pair == nil)
    }

    @Test func representativePalettesAvoidHardBlackWhiteBackgrounds() {
        let themes: [(TerminalColorScheme, TerminalThemePalette, TerminalSRGBColor, TerminalSRGBColor)] = [
            (.dark, Self.mosshDarkPalette, Self.srgb(0xf7f7f7), Self.srgb(0xffffff)),
            (.dark, Self.draculaPalette, Self.srgb(0xf7f7f7), Self.srgb(0xffffff)),
            (.light, Self.solarizedLightPalette, Self.srgb(0x101010), Self.srgb(0x000000))
        ]

        for (scheme, palette, foreground, background) in themes {
            let correction = TerminalContrastCorrection(
                isEnabled: true,
                localColorScheme: scheme,
                localPalette: palette
            )

            let pair = correction.correctedPair(
                foreground: foreground,
                background: background,
                hasExplicitForeground: false,
                backgroundRole: .remoteExplicit
            )

            #expect(pair != nil)
            guard let pair else {
                continue
            }
            #expect(pair.foreground.contrastRatio(with: pair.background) >= 4.5)
            #expect(pair.background != .black)
            #expect(pair.background != .white)
        }
    }

    @Test func allMosshThemesHarmonizeOppositeNeutralExtremes() {
        for theme in Self.allMosshThemeFixtures {
            let correction = Self.correction(for: theme)
            let localBackground = Self.srgb(theme.background)

            switch theme.colorScheme {
            case .dark:
                let explicitBackground = Self.srgb(0xeeeeee)
                let explicitPair = correction.correctedPair(
                    foreground: Self.srgb(0x262626),
                    background: explicitBackground,
                    hasExplicitForeground: true,
                    backgroundRole: .remoteExplicit
                )
                #expect(explicitPair != nil)
                if let explicitPair {
                    #expect(explicitPair.foreground.contrastRatio(with: explicitPair.background) >= 4.5)
                    #expect(explicitPair.background != explicitBackground)
                    #expect(explicitPair.background != localBackground)
                    #expect(explicitPair.background.relativeLuminance < explicitBackground.relativeLuminance)
                    #expect(explicitPair.background.relativeLuminance > localBackground.relativeLuminance)
                }

                let invertedPair = correction.correctedPair(
                    foreground: Self.srgb(theme.foreground),
                    background: .white,
                    hasExplicitForeground: false,
                    backgroundRole: .invertedDefaultSurface
                )
                #expect(invertedPair != nil)
                if let invertedPair {
                    #expect(invertedPair.foreground.contrastRatio(with: invertedPair.background) >= 4.5)
                    #expect(invertedPair.background != .white)
                    #expect(invertedPair.background != localBackground)
                    #expect(invertedPair.background.relativeLuminance > localBackground.relativeLuminance)
                }
            case .light:
                let explicitPair = correction.correctedPair(
                    foreground: .white,
                    background: .black,
                    hasExplicitForeground: true,
                    backgroundRole: .remoteExplicit
                )
                #expect(explicitPair != nil)
                if let explicitPair {
                    #expect(explicitPair.foreground.contrastRatio(with: explicitPair.background) >= 4.5)
                    #expect(explicitPair.background != .black)
                    #expect(explicitPair.background != localBackground)
                    #expect(explicitPair.background.relativeLuminance > TerminalSRGBColor.black.relativeLuminance)
                    #expect(explicitPair.background.relativeLuminance < localBackground.relativeLuminance)
                }

                let invertedPair = correction.correctedPair(
                    foreground: Self.srgb(theme.foreground),
                    background: .black,
                    hasExplicitForeground: false,
                    backgroundRole: .invertedDefaultSurface
                )
                #expect(invertedPair != nil)
                if let invertedPair {
                    #expect(invertedPair.foreground.contrastRatio(with: invertedPair.background) >= 4.5)
                    #expect(invertedPair.background != .black)
                    #expect(invertedPair.background != localBackground)
                    #expect(invertedPair.background.relativeLuminance < localBackground.relativeLuminance)
                }
            }
        }
    }

    @Test func allMosshThemesProtectThemeAnsiAndSameSchemeBackgrounds() {
        for theme in Self.allMosshThemeFixtures {
            let correction = Self.correction(for: theme)

            for index in 0..<theme.ansi.count {
                let background = Self.srgb(theme.ansi[index])
                let role = correction.backgroundRole(
                    originalAttribute: Attribute(fg: .defaultColor, bg: .ansi256(code: UInt8(index)), style: .none),
                    resolvedBackgroundAttribute: .ansi256(code: UInt8(index)),
                    resolvedBackground: background
                )
                #expect(role == .themeAnsi)
                let pair = correction.correctedPair(
                    foreground: .black,
                    background: background,
                    hasExplicitForeground: false,
                    backgroundRole: role
                )
                #expect(pair == nil)
            }

            let sameSchemeBackground = theme.colorScheme == .dark ? Self.srgb(0x101010) : Self.srgb(0xf7f7f7)
            let sameSchemePair = correction.correctedPair(
                foreground: theme.colorScheme == .dark ? .white : .black,
                background: sameSchemeBackground,
                hasExplicitForeground: true,
                backgroundRole: .remoteExplicit
            )
            #expect(sameSchemePair == nil)
        }
    }

    @Test func allMosshThemesDoNotHarmonizeNonExtremeOrSaturatedBlocks() {
        for theme in Self.allMosshThemeFixtures {
            let correction = Self.correction(for: theme)
            let nonExtremeBackground = theme.colorScheme == .dark ? Self.srgb(0xe0e0e0) : Self.srgb(0x555555)
            let nonExtremePair = correction.correctedPair(
                foreground: theme.colorScheme == .dark ? .black : .white,
                background: nonExtremeBackground,
                hasExplicitForeground: true,
                backgroundRole: .remoteExplicit
            )
            #expect(nonExtremePair == nil)

            let saturatedPair = correction.correctedPair(
                foreground: .black,
                background: Self.srgb(0x00ff00),
                hasExplicitForeground: true,
                backgroundRole: .remoteExplicit
            )
            #expect(saturatedPair == nil)

            let statusPair = correction.correctedPair(
                foreground: .black,
                background: Self.srgb(0xe3b341),
                hasExplicitForeground: true,
                backgroundRole: .remoteExplicit
            )
            #expect(statusPair == nil)
        }
    }

    @Test func allMosshThemesHarmonizePastelDiffBackgrounds() {
        for theme in Self.allMosshThemeFixtures {
            let correction = Self.correction(for: theme)
            let localBackground = Self.srgb(theme.background)
            let pastelBackground = theme.colorScheme == .dark ? Self.srgb(0xddffdd) : Self.srgb(0x304020)
            let pair = correction.correctedPair(
                foreground: theme.colorScheme == .dark ? .black : .white,
                background: pastelBackground,
                hasExplicitForeground: true,
                backgroundRole: .remoteExplicit
            )

            guard pastelBackground.contrastRatio(with: localBackground) >= 10.0 else {
                #expect(pair == nil)
                continue
            }

            #expect(pair != nil)
            guard let pair else {
                continue
            }
            #expect(pair.foreground.contrastRatio(with: pair.background) >= 4.5)
            #expect(pair.background != pastelBackground)
            #expect(pair.background != localBackground)
            if theme.colorScheme == .dark {
                #expect(pair.background.relativeLuminance < pastelBackground.relativeLuminance)
                #expect(pair.background.relativeLuminance > localBackground.relativeLuminance)
            } else {
                #expect(pair.background.relativeLuminance > pastelBackground.relativeLuminance)
                #expect(pair.background.relativeLuminance < localBackground.relativeLuminance)
            }
        }
    }

    @Test func attributeEmptyDefaultInvertedBackgroundHarmonizesWhenExtreme() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.mosshDarkPalette,
            harmonizeReadableNeutralExtremes: true
        )

        let role = correction.backgroundRole(
            originalAttribute: .empty,
            resolvedBackgroundAttribute: .defaultInvertedColor,
            resolvedBackground: .white
        )

        #expect(role == .invertedDefaultSurface)
        let pair = correction.correctedPair(
            foreground: Self.srgb(0xe6edf3),
            background: .white,
            hasExplicitForeground: false,
            backgroundRole: role
        )

        #expect(pair != nil)
        guard let pair else {
            return
        }
        #expect(pair.foreground.contrastRatio(with: pair.background) >= 4.5)
        #expect(pair.background != .white)
    }

    @Test func defaultInvertedBackgroundDoesNotHarmonizeWhenNotExtreme() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.mosshDarkPalette,
            harmonizeReadableNeutralExtremes: true
        )
        let role = correction.backgroundRole(
            originalAttribute: .empty,
            resolvedBackgroundAttribute: .defaultInvertedColor,
            resolvedBackground: Self.srgb(0xb0b0b0)
        )

        #expect(role == .invertedDefaultSurface)
        let pair = correction.correctedPair(
            foreground: Self.srgb(0xe6edf3),
            background: Self.srgb(0xb0b0b0),
            hasExplicitForeground: false,
            backgroundRole: role
        )
        #expect(pair == nil)
    }

    @Test func themeAnsiBackgroundIsProtected() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.mosshDarkPalette,
            harmonizeReadablePastelAccents: true
        )
        let attribute = Attribute(fg: .defaultColor, bg: .ansi256(code: 2), style: .none)

        let role = correction.backgroundRole(
            originalAttribute: attribute,
            resolvedBackgroundAttribute: .ansi256(code: 2),
            resolvedBackground: Self.srgb(0x3fcc65)
        )

        #expect(role == .themeAnsi)
        let pair = correction.correctedPair(
            foreground: .black,
            background: Self.srgb(0x3fcc65),
            hasExplicitForeground: false,
            backgroundRole: role
        )
        #expect(pair == nil)
    }

    @Test func changedAnsiBackgroundIsRemoteExplicit() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.mosshDarkPalette,
            harmonizeReadablePastelAccents: true
        )
        let attribute = Attribute(fg: .defaultColor, bg: .ansi256(code: 2), style: .none)

        let role = correction.backgroundRole(
            originalAttribute: attribute,
            resolvedBackgroundAttribute: .ansi256(code: 2),
            resolvedBackground: Self.srgb(0xddffdd)
        )

        #expect(role == .remoteExplicit)
    }

    @Test func readablePastelAccentBackgroundUsesOneSurfaceForMixedForegrounds() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.mosshDarkPalette,
            harmonizeReadableNeutralExtremes: true,
            harmonizeReadablePastelAccents: true
        )
        let background = Self.srgb(0xddffdd)

        let defaultPair = correction.correctedPair(
            foreground: Self.srgb(0xe6edf3),
            background: background,
            hasExplicitForeground: false,
            backgroundRole: .remoteExplicit
        )
        let magentaPair = correction.correctedPair(
            foreground: Self.srgb(0xff00ff),
            background: background,
            hasExplicitForeground: true,
            backgroundRole: .remoteExplicit
        )
        let underlinePair = correction.correctedPair(
            foreground: .black,
            background: background,
            underline: Self.srgb(0xff00ff),
            hasExplicitForeground: true,
            hasExplicitUnderline: true,
            backgroundRole: .remoteExplicit
        )

        #expect(defaultPair != nil)
        #expect(magentaPair != nil)
        #expect(underlinePair != nil)
        guard let defaultPair, let magentaPair, let underlinePair else {
            return
        }
        #expect(defaultPair.background == magentaPair.background)
        #expect(defaultPair.background == underlinePair.background)
        #expect(defaultPair.foreground.contrastRatio(with: defaultPair.background) >= 4.5)
        #expect(magentaPair.foreground.contrastRatio(with: magentaPair.background) >= 4.5)
        #expect((underlinePair.underline?.contrastRatio(with: underlinePair.background) ?? 0) >= 4.5)
    }

    @Test func darkPastelAccentBackgroundOnLightLocalUsesThemeSurface() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .light,
            localPalette: Self.solarizedLightPalette,
            harmonizeReadableNeutralExtremes: true,
            harmonizeReadablePastelAccents: true
        )
        let background = Self.srgb(0x304020)

        let pair = correction.correctedPair(
            foreground: .white,
            background: background,
            hasExplicitForeground: true,
            backgroundRole: .remoteExplicit
        )

        #expect(pair != nil)
        guard let pair else {
            return
        }
        #expect(pair.foreground.contrastRatio(with: pair.background) >= 4.5)
        #expect(pair.background != background)
        #expect(pair.background.relativeLuminance > background.relativeLuminance)
        #expect(pair.background.relativeLuminance < Self.srgb(0xfdf6e3).relativeLuminance)
    }

    @Test func pastelAccentSwitchControlsReadableColoredBackgrounds() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.mosshDarkPalette,
            harmonizeReadableNeutralExtremes: true,
            harmonizeReadablePastelAccents: false
        )

        let pair = correction.correctedPair(
            foreground: .black,
            background: Self.srgb(0xddffdd),
            hasExplicitForeground: true,
            backgroundRole: .remoteExplicit
        )

        #expect(pair == nil)
    }

    @Test func statusYellowAndSaturatedColorsDoNotHarmonize() {
        let correction = TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: .dark,
            localPalette: Self.mosshDarkPalette,
            harmonizeReadableNeutralExtremes: true,
            harmonizeReadablePastelAccents: true
        )

        let statusPair = correction.correctedPair(
            foreground: .black,
            background: Self.srgb(0xe3b341),
            hasExplicitForeground: true,
            backgroundRole: .remoteExplicit
        )
        let saturatedPair = correction.correctedPair(
            foreground: .black,
            background: Self.srgb(0x00ff00),
            hasExplicitForeground: true,
            backgroundRole: .remoteExplicit
        )

        #expect(statusPair == nil)
        #expect(saturatedPair == nil)
    }

    private static let mosshDarkPalette = palette(
        background: 0x0a0d10,
        foreground: 0xe6edf3,
        ansi: [
            0x0d1117, 0xf85149, 0x3fcc65, 0xd29922,
            0x58a6ff, 0xbc8cff, 0x39c5cf, 0xb1bac4,
            0x6e7686, 0xff7b72, 0x56d364, 0xe3b341,
            0x79c0ff, 0xd2a8ff, 0x56d4dd, 0xf0f6fc
        ]
    )

    private static let draculaPalette = palette(
        background: 0x282a36,
        foreground: 0xf8f8f2,
        ansi: [
            0x21222c, 0xff5555, 0x50fa7b, 0xf1fa8c,
            0xbd93f9, 0xff79c6, 0x8be9fd, 0xbfbfbf,
            0x4d4d4d, 0xff6e67, 0x5af78e, 0xf4f99d,
            0xcaa9fa, 0xff92d0, 0x9aedfe, 0xe6e6e6
        ]
    )

    private static let solarizedLightPalette = palette(
        background: 0xfdf6e3,
        foreground: 0x657b83,
        ansi: [
            0x073642, 0xdc322f, 0x859900, 0xb58900,
            0x268bd2, 0xd33682, 0x2aa198, 0xeee8d5,
            0x002b36, 0xcb4b16, 0x586e75, 0x657b83,
            0x839496, 0x6c71c4, 0x93a1a1, 0xfdf6e3
        ]
    )

    private struct ThemeFixture {
        let id: String
        let colorScheme: TerminalColorScheme
        let background: UInt32
        let foreground: UInt32
        let ansi: [UInt32]
    }

    private static let allMosshThemeFixtures: [ThemeFixture] = [
        ThemeFixture(
            id: "mossh-dark",
            colorScheme: .dark,
            background: 0x0a0d10,
            foreground: 0xe6edf3,
            ansi: [
                0x0d1117, 0xf85149, 0x3fcc65, 0xd29922,
                0x58a6ff, 0xbc8cff, 0x39c5cf, 0xb1bac4,
                0x6e7686, 0xff7b72, 0x56d364, 0xe3b341,
                0x79c0ff, 0xd2a8ff, 0x56d4dd, 0xf0f6fc
            ]
        ),
        ThemeFixture(
            id: "dracula",
            colorScheme: .dark,
            background: 0x282a36,
            foreground: 0xf8f8f2,
            ansi: [
                0x21222c, 0xff5555, 0x50fa7b, 0xf1fa8c,
                0xbd93f9, 0xff79c6, 0x8be9fd, 0xbfbfbf,
                0x4d4d4d, 0xff6e67, 0x5af78e, 0xf4f99d,
                0xcaa9fa, 0xff92d0, 0x9aedfe, 0xe6e6e6
            ]
        ),
        ThemeFixture(
            id: "solarized-dark",
            colorScheme: .dark,
            background: 0x002b36,
            foreground: 0x839496,
            ansi: [
                0x073642, 0xdc322f, 0x859900, 0xb58900,
                0x268bd2, 0xd33682, 0x2aa198, 0xeee8d5,
                0x002b36, 0xcb4b16, 0x586e75, 0x657b83,
                0x839496, 0x6c71c4, 0x93a1a1, 0xfdf6e3
            ]
        ),
        ThemeFixture(
            id: "solarized-light",
            colorScheme: .light,
            background: 0xfdf6e3,
            foreground: 0x657b83,
            ansi: [
                0x073642, 0xdc322f, 0x859900, 0xb58900,
                0x268bd2, 0xd33682, 0x2aa198, 0xeee8d5,
                0x002b36, 0xcb4b16, 0x586e75, 0x657b83,
                0x839496, 0x6c71c4, 0x93a1a1, 0xfdf6e3
            ]
        ),
        ThemeFixture(
            id: "gruvbox-dark",
            colorScheme: .dark,
            background: 0x282828,
            foreground: 0xebdbb2,
            ansi: [
                0x282828, 0xcc241d, 0x98971a, 0xd79921,
                0x458588, 0xb16286, 0x689d6a, 0xa89984,
                0x928374, 0xfb4934, 0xb8bb26, 0xfabd2f,
                0x83a598, 0xd3869b, 0x8ec07c, 0xebdbb2
            ]
        ),
        ThemeFixture(
            id: "gruvbox-light",
            colorScheme: .light,
            background: 0xfbf1c7,
            foreground: 0x3c3836,
            ansi: [
                0x282828, 0xcc241d, 0x98971a, 0xd79921,
                0x458588, 0xb16286, 0x689d6a, 0x7c6f64,
                0x928374, 0x9d0006, 0x79740e, 0xb57614,
                0x076678, 0x8f3f71, 0x427b58, 0x3c3836
            ]
        ),
        ThemeFixture(
            id: "nord",
            colorScheme: .dark,
            background: 0x2e3440,
            foreground: 0xd8dee9,
            ansi: [
                0x3b4252, 0xbf616a, 0xa3be8c, 0xebcb8b,
                0x81a1c1, 0xb48ead, 0x88c0d0, 0xe5e9f0,
                0x4c566a, 0xbf616a, 0xa3be8c, 0xebcb8b,
                0x81a1c1, 0xb48ead, 0x8fbcbb, 0xeceff4
            ]
        ),
        ThemeFixture(
            id: "one-dark",
            colorScheme: .dark,
            background: 0x282c34,
            foreground: 0xabb2bf,
            ansi: [
                0x282c34, 0xe06c75, 0x98c379, 0xe5c07b,
                0x61afef, 0xc678dd, 0x56b6c2, 0xabb2bf,
                0x5c6370, 0xe06c75, 0x98c379, 0xe5c07b,
                0x61afef, 0xc678dd, 0x56b6c2, 0xffffff
            ]
        ),
        ThemeFixture(
            id: "monokai",
            colorScheme: .dark,
            background: 0x272822,
            foreground: 0xf8f8f2,
            ansi: [
                0x272822, 0xf92672, 0xa6e22e, 0xf4bf75,
                0x66d9ef, 0xae81ff, 0xa1efe4, 0xf8f8f2,
                0x75715e, 0xf92672, 0xa6e22e, 0xe6db74,
                0x66d9ef, 0xae81ff, 0xa1efe4, 0xf9f8f5
            ]
        ),
        ThemeFixture(
            id: "catppuccin-mocha",
            colorScheme: .dark,
            background: 0x1e1e2e,
            foreground: 0xcdd6f4,
            ansi: [
                0x45475a, 0xf38ba8, 0xa6e3a1, 0xf9e2af,
                0x89b4fa, 0xf5c2e7, 0x94e2d5, 0xbac2de,
                0x585b70, 0xf38ba8, 0xa6e3a1, 0xf9e2af,
                0x89b4fa, 0xf5c2e7, 0x94e2d5, 0xa6adc8
            ]
        ),
        ThemeFixture(
            id: "tokyo-night",
            colorScheme: .dark,
            background: 0x1a1b26,
            foreground: 0xc0caf5,
            ansi: [
                0x15161e, 0xf7768e, 0x9ece6a, 0xe0af68,
                0x7aa2f7, 0xbb9af7, 0x7dcfff, 0xa9b1d6,
                0x414868, 0xf7768e, 0x9ece6a, 0xe0af68,
                0x7aa2f7, 0xbb9af7, 0x7dcfff, 0xc0caf5
            ]
        )
    ]

    private static func correction(for theme: ThemeFixture) -> TerminalContrastCorrection {
        TerminalContrastCorrection(
            isEnabled: true,
            localColorScheme: theme.colorScheme,
            localPalette: palette(background: theme.background, foreground: theme.foreground, ansi: theme.ansi),
            harmonizeReadableNeutralExtremes: true,
            harmonizeReadablePastelAccents: true
        )
    }

    private static func palette(background: UInt32, foreground: UInt32, ansi: [UInt32]) -> TerminalThemePalette {
        TerminalThemePalette(
            background: color(background),
            foreground: color(foreground),
            ansiColors: ansi.map(color)
        )
    }

    private static func color(_ hex: UInt32) -> Color {
        Color(
            red: UInt16((hex >> 16) & 0xff) * 257,
            green: UInt16((hex >> 8) & 0xff) * 257,
            blue: UInt16(hex & 0xff) * 257
        )
    }

    private static func srgb(_ hex: UInt32) -> TerminalSRGBColor {
        TerminalSRGBColor(
            red: Double((hex >> 16) & 0xff) / 255.0,
            green: Double((hex >> 8) & 0xff) / 255.0,
            blue: Double(hex & 0xff) / 255.0
        )
    }
}
