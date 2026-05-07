import Testing
@testable import SwiftTerm

final class TerminalVisibleBottomOccupancyTests {
    @Test func testEmptyScreenTreatsCursorRowAsOccupiedByDefault() {
        let (terminal, _) = TerminalTestHarness.makeTerminal(cols: 10, rows: 4)

        let occupancy = terminal.visibleBottomOccupancy()

        #expect(occupancy.rows == 4)
        #expect(occupancy.cursorRow == 0)
        #expect(occupancy.lastContentRow == nil)
        #expect(occupancy.lastOccupiedRow == 0)
        #expect(occupancy.bottomBlankRows == 3)
        #expect(occupancy.isAlternateBuffer == false)
    }

    @Test func testEmptyScreenCanIgnoreCursorRow() {
        let (terminal, _) = TerminalTestHarness.makeTerminal(cols: 10, rows: 4)

        let occupancy = terminal.visibleBottomOccupancy(includeCursor: false)

        #expect(occupancy.lastContentRow == nil)
        #expect(occupancy.lastOccupiedRow == nil)
        #expect(occupancy.bottomBlankRows == 4)
    }

    @Test func testFullScreenContentHasNoBottomBlankRows() {
        let (terminal, _) = TerminalTestHarness.makeTerminal(cols: 10, rows: 3)
        let esc = "\u{1b}"

        terminal.feed(text: "\(esc)[1;1HA\(esc)[2;1HB\(esc)[3;1HC")

        let occupancy = terminal.visibleBottomOccupancy()

        #expect(occupancy.lastContentRow == 2)
        #expect(occupancy.lastOccupiedRow == 2)
        #expect(occupancy.bottomBlankRows == 0)
    }

    @Test func testPartialBottomBlankRowsAreMeasuredFromLastContent() {
        let (terminal, _) = TerminalTestHarness.makeTerminal(cols: 10, rows: 5)
        let esc = "\u{1b}"

        terminal.feed(text: "\(esc)[3;1Hmiddle")

        let occupancy = terminal.visibleBottomOccupancy()

        #expect(occupancy.cursorRow == 2)
        #expect(occupancy.lastContentRow == 2)
        #expect(occupancy.lastOccupiedRow == 2)
        #expect(occupancy.bottomBlankRows == 2)
    }

    @Test func testCursorOnlyRowCountsAsOccupied() {
        let (terminal, _) = TerminalTestHarness.makeTerminal(cols: 10, rows: 5)
        let esc = "\u{1b}"

        terminal.feed(text: "\(esc)[4;1H")

        let occupancy = terminal.visibleBottomOccupancy()

        #expect(occupancy.lastContentRow == nil)
        #expect(occupancy.cursorRow == 3)
        #expect(occupancy.lastOccupiedRow == 3)
        #expect(occupancy.bottomBlankRows == 1)
    }

    @Test func testStyledBlankCellsCanCountAsContent() {
        let (terminal, _) = TerminalTestHarness.makeTerminal(cols: 10, rows: 4)
        let styledAttribute = Attribute(fg: .defaultColor, bg: .ansi256(code: 1), style: .none)
        terminal.buffer.lines[2][0] = CharData(attribute: styledAttribute)

        let styledOccupancy = terminal.visibleBottomOccupancy(
            countStyledCellsAsContent: true,
            includeCursor: false
        )
        let textOnlyOccupancy = terminal.visibleBottomOccupancy(
            countStyledCellsAsContent: false,
            includeCursor: false
        )

        #expect(styledOccupancy.lastContentRow == 2)
        #expect(styledOccupancy.bottomBlankRows == 1)
        #expect(textOnlyOccupancy.lastContentRow == nil)
        #expect(textOnlyOccupancy.bottomBlankRows == 4)
    }

    @Test func testAlternateBufferIsReported() {
        let (terminal, _) = TerminalTestHarness.makeTerminal(cols: 10, rows: 4)

        terminal.feed(text: "\u{1b}[?1049h")

        let occupancy = terminal.visibleBottomOccupancy()

        #expect(occupancy.isAlternateBuffer)
    }

    @Test func testSynchronizedOutputUsesDisplayBuffer() {
        let (terminal, _) = TerminalTestHarness.makeTerminal(cols: 10, rows: 3)
        let esc = "\u{1b}"

        terminal.feed(text: "\(esc)[2J\(esc)[3;1HOLD")
        #expect(terminal.visibleBottomOccupancy(includeCursor: false).lastContentRow == 2)

        terminal.feed(text: "\(esc)[?2026h")
        terminal.feed(text: "\(esc)[2J\(esc)[HNEW")

        let synchronizedOccupancy = terminal.visibleBottomOccupancy(includeCursor: false)
        #expect(synchronizedOccupancy.lastContentRow == 2)
        #expect(synchronizedOccupancy.bottomBlankRows == 0)

        terminal.feed(text: "\(esc)[?2026l")

        let settledOccupancy = terminal.visibleBottomOccupancy(includeCursor: false)
        #expect(settledOccupancy.lastContentRow == 0)
        #expect(settledOccupancy.bottomBlankRows == 2)
    }
}
