#if os(macOS)
import AppKit
import Testing

@testable import SwiftTerm

@MainActor
struct ColorRenderInvalidationTests {
    @Test func colorsChangedAdvancesGenerationAndClearsAttributeCaches() {
        let view = Self.makeTerminalView()
        let attribute = Attribute(fg: .ansi256(code: 235), bg: .ansi256(code: 255), style: .none)

        _ = view.getAttributes(attribute, withUrl: false)
        _ = view.getAttributes(attribute, withUrl: true)
        #expect(!view.attributes.isEmpty)
        #expect(!view.urlAttributes.isEmpty)

        let before = view.colorRenderGeneration
        view.colorsChanged()

        #expect(view.colorRenderGeneration == before &+ 1)
        #expect(view.attributes.isEmpty)
        #expect(view.urlAttributes.isEmpty)
    }

    @Test func contrastCorrectionChangeInvalidatesCachedAttributes() {
        let view = Self.makeTerminalView()
        let attribute = Attribute(fg: .ansi256(code: 235), bg: .ansi256(code: 255), style: .none)
        view.contrastCorrection = Self.darkCorrection

        let correctedAttributes = view.getAttributes(attribute, withUrl: false)
        let correctedBackground = Self.rgb8(correctedAttributes?[.backgroundColor] as? NSColor)
        #expect(correctedBackground != nil)
        #expect(!view.attributes.isEmpty)

        let before = view.colorRenderGeneration
        view.contrastCorrection = .disabled

        #expect(view.colorRenderGeneration == before &+ 1)
        #expect(view.attributes.isEmpty)

        let uncorrectedAttributes = view.getAttributes(attribute, withUrl: false)
        let uncorrectedBackground = Self.rgb8(uncorrectedAttributes?[.backgroundColor] as? NSColor)
        #expect(uncorrectedBackground?.0 == 238)
        #expect(uncorrectedBackground?.1 == 238)
        #expect(uncorrectedBackground?.2 == 238)
        #expect(
            correctedBackground?.0 != uncorrectedBackground?.0 ||
            correctedBackground?.1 != uncorrectedBackground?.1 ||
            correctedBackground?.2 != uncorrectedBackground?.2
        )
    }

    private static func makeTerminalView() -> TerminalView {
        let view = TerminalView(frame: CGRect(origin: .zero, size: CGSize(width: 160, height: 80)))
        view.nativeBackgroundColor = .black
        view.nativeForegroundColor = .white
        view.terminal.ansi256PaletteStrategy = .xterm
        view.installColors(Color.xtermColors)
        return view
    }

    private static let darkCorrection = TerminalContrastCorrection(
        isEnabled: true,
        localColorScheme: .dark,
        localPalette: TerminalThemePalette(
            background: Color(red8: 10, green8: 13, blue8: 16),
            foreground: Color(red8: 230, green8: 237, blue8: 243),
            ansiColors: [
                Color(red8: 13, green8: 17, blue8: 23),
                Color(red8: 248, green8: 81, blue8: 73),
                Color(red8: 63, green8: 204, blue8: 101),
                Color(red8: 210, green8: 153, blue8: 34),
                Color(red8: 88, green8: 166, blue8: 255),
                Color(red8: 188, green8: 140, blue8: 255),
                Color(red8: 57, green8: 197, blue8: 207),
                Color(red8: 177, green8: 186, blue8: 196),
                Color(red8: 110, green8: 118, blue8: 134),
                Color(red8: 255, green8: 123, blue8: 114),
                Color(red8: 86, green8: 211, blue8: 100),
                Color(red8: 227, green8: 179, blue8: 65),
                Color(red8: 121, green8: 192, blue8: 255),
                Color(red8: 210, green8: 168, blue8: 255),
                Color(red8: 86, green8: 212, blue8: 221),
                Color(red8: 240, green8: 246, blue8: 252)
            ]
        ),
        harmonizeReadableNeutralExtremes: true,
        harmonizeReadablePastelAccents: true
    )

    private static func rgb8(_ color: NSColor?) -> (Int, Int, Int)? {
        guard let color = color?.usingColorSpace(.deviceRGB) else {
            return nil
        }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (
            Int((red * 255).rounded()),
            Int((green * 255).rounded()),
            Int((blue * 255).rounded())
        )
    }
}
#endif
