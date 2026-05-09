import Foundation
import RichSwift

public struct SyntaxHighlightedScrollView: CanvasRenderable, Equatable, Sendable {
    public var frame: Rect
    public var source: String
    public var language: String
    public var lineNumbers: Bool
    public var scrollOffset: Int
    public var isFocused: Bool
    public var fillStyle: TerminalStyle
    public var scrollbarStyle: TerminalStyle
    public var thumbStyle: TerminalStyle

    public init(
        frame: Rect,
        source: String,
        language: String = "tcss",
        lineNumbers: Bool = true,
        scrollOffset: Int = 0,
        isFocused: Bool = false,
        fillStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .black),
        scrollbarStyle: TerminalStyle = TerminalStyle(foreground: .white, background: .brightBlack),
        thumbStyle: TerminalStyle = TerminalStyle(foreground: .brightWhite, background: .blue, bold: true)
    ) {
        self.frame = frame
        self.source = source
        self.language = language
        self.lineNumbers = lineNumbers
        self.scrollOffset = scrollOffset
        self.isFocused = isFocused
        self.fillStyle = fillStyle
        self.scrollbarStyle = scrollbarStyle
        self.thumbStyle = thumbStyle
    }

    public var contentHeight: Int {
        highlightedLines.count
    }

    public mutating func handle(_ event: InputEvent) -> ScrollViewCommand {
        switch event {
        case .key(.down):
            guard isFocused else { return .none }
            return scroll(by: 1)
        case .key(.up):
            guard isFocused else { return .none }
            return scroll(by: -1)
        case .mouse(let mouse):
            if mouse.button == .left,
               mouse.pressed,
               contentHeight > frame.height,
               mouse.location.x == frame.x + frame.width - 1 {
                isFocused = true
                return scroll(toThumbLocation: mouse.location)
            }
            guard frame.contains(mouse.location) else { return .none }
            switch mouse.button {
            case .scrollDown:
                return scroll(by: 1)
            case .scrollUp:
                return scroll(by: -1)
            case .left:
                if mouse.pressed {
                    isFocused = true
                    return .focused
                }
                return .none
            default:
                return .none
            }
        default:
            return .none
        }
    }

    public func render(in canvas: inout Canvas) {
        guard frame.width > 0, frame.height > 0 else { return }
        canvas.fill(rect: frame, style: fillStyle)

        let lines = highlightedLines
        let contentWidth = max(0, frame.width - scrollbarWidth)
        for rowOffset in 0..<frame.height {
            let contentIndex = scrollOffset + rowOffset
            guard lines.indices.contains(contentIndex) else { break }
            drawANSILine(lines[contentIndex], at: Point(x: frame.x, y: frame.y + rowOffset), width: contentWidth, in: &canvas)
        }

        renderScrollbar(in: &canvas)
    }

    private var highlightedLines: [String] {
        Syntax(source, language: language, lineNumbers: lineNumbers)
            .render(in: RenderContext(width: max(1, frame.width), colorMode: .standard, markup: false))
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
    }

    private var scrollbarWidth: Int {
        contentHeight > frame.height ? 1 : 0
    }

    private var maxScrollOffset: Int {
        max(0, contentHeight - frame.height)
    }

    private mutating func scroll(by delta: Int) -> ScrollViewCommand {
        let old = scrollOffset
        scrollOffset = min(max(0, scrollOffset + delta), maxScrollOffset)
        return old == scrollOffset ? .none : .scrolled(scrollOffset)
    }

    private mutating func scroll(toThumbLocation location: Point) -> ScrollViewCommand {
        guard contentHeight > frame.height, frame.height > 0 else { return .none }
        let old = scrollOffset
        let relativeY = min(max(0, location.y - frame.y), frame.height - 1)
        let thumbHeight = max(1, frame.height * frame.height / max(1, contentHeight))
        let travel = max(1, frame.height - thumbHeight)
        scrollOffset = min(maxScrollOffset, max(0, relativeY * maxScrollOffset / travel))
        return old == scrollOffset ? .focused : .scrolled(scrollOffset)
    }

    private func renderScrollbar(in canvas: inout Canvas) {
        guard contentHeight > frame.height, frame.width > 0 else { return }
        let x = frame.x + frame.width - 1
        canvas.fill(rect: Rect(x: x, y: frame.y, width: 1, height: frame.height), style: scrollbarStyle)

        let thumbHeight = max(1, frame.height * frame.height / max(1, contentHeight))
        let travel = max(0, frame.height - thumbHeight)
        let thumbY = frame.y + (maxScrollOffset == 0 ? 0 : (scrollOffset * travel / maxScrollOffset))
        canvas.fill(rect: Rect(x: x, y: thumbY, width: 1, height: thumbHeight), style: thumbStyle)
    }

    private func drawANSILine(_ line: String, at point: Point, width: Int, in canvas: inout Canvas) {
        let characters = Array(line)
        var index = 0
        var column = 0
        var style = fillStyle

        while index < characters.count, column < width {
            if characters[index] == "\u{001B}" {
                consumeANSISequence(characters, index: &index, style: &style)
                continue
            }
            canvas[point.x + column, point.y] = Cell(characters[index], style: style)
            column += 1
            index += 1
        }
    }

    private func consumeANSISequence(_ characters: [Character], index: inout Int, style: inout TerminalStyle) {
        guard index + 1 < characters.count, characters[index + 1] == "[" else {
            index += 1
            return
        }

        index += 2
        var body = ""
        while index < characters.count, characters[index] != "m" {
            body.append(characters[index])
            index += 1
        }
        if index < characters.count {
            index += 1
        }

        applyANSICodes(body.split(separator: ";").compactMap { Int($0) }, to: &style)
    }

    private func applyANSICodes(_ codes: [Int], to style: inout TerminalStyle) {
        let codes = codes.isEmpty ? [0] : codes
        var index = 0
        while index < codes.count {
            let code = codes[index]
            switch code {
            case 0:
                style = fillStyle
            case 1:
                style.bold = true
            case 2:
                style.foreground = .brightBlack
            case 7:
                style.inverse = true
            case 30...37:
                style.foreground = .ansi(code - 30)
            case 40...47:
                style.background = .ansi(code - 40)
            case 90...97:
                style.foreground = .ansi(code - 90 + 8)
            case 100...107:
                style.background = .ansi(code - 100 + 8)
            case 38, 48:
                parseExtendedColor(codes, index: &index, background: code == 48, style: &style)
            default:
                break
            }
            index += 1
        }
    }

    private func parseExtendedColor(_ codes: [Int], index: inout Int, background: Bool, style: inout TerminalStyle) {
        guard index + 2 < codes.count else { return }
        let mode = codes[index + 1]
        if mode == 5 {
            let color = TerminalColor.ansi(codes[index + 2])
            if background {
                style.background = color
            } else {
                style.foreground = color
            }
            index += 2
        } else if mode == 2, index + 4 < codes.count {
            let color = TerminalColor.rgb(UInt8(clamping: codes[index + 2]), UInt8(clamping: codes[index + 3]), UInt8(clamping: codes[index + 4]))
            if background {
                style.background = color
            } else {
                style.foreground = color
            }
            index += 4
        }
    }
}
