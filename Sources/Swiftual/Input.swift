import Foundation

public enum Key: Equatable, Sendable {
    case character(Character)
    case enter
    case escape
    case tab
    case backspace
    case up
    case down
    case left
    case right
    case controlC
    case controlP
    case unknown(String)
}

public enum MouseButton: Equatable, Sendable {
    case left
    case middle
    case right
    case release
    case scrollUp
    case scrollDown
    case unknown(Int)
}

public struct MouseEvent: Equatable, Sendable {
    public var button: MouseButton
    public var location: Point
    public var pressed: Bool

    public init(button: MouseButton, location: Point, pressed: Bool) {
        self.button = button
        self.location = location
        self.pressed = pressed
    }
}

public enum InputEvent: Equatable, Sendable {
    case key(Key)
    case mouse(MouseEvent)
}

public struct InputParser: Sendable {
    public init() {}

    public func parse(_ bytes: [UInt8]) -> [InputEvent] {
        guard !bytes.isEmpty else { return [] }
        let text = String(decoding: bytes, as: UTF8.self)

        if text.count > 1, !text.hasPrefix("\u{1B}[<") {
            var events: [InputEvent] = []
            var index = text.startIndex

            while index < text.endIndex {
                let remaining = text[index...]
                if let arrow = parseArrowPrefix(remaining) {
                    events.append(.key(arrow.key))
                    index = text.index(index, offsetBy: arrow.length)
                } else {
                    let character = text[index]
                    events.append(contentsOf: parse(Array(String(character).utf8)))
                    index = text.index(after: index)
                }
            }

            return events
        }

        if let mouse = parseSGRMouse(text) {
            return [.mouse(mouse)]
        }

        switch text {
        case "\u{3}":
            return [.key(.controlC)]
        case "\u{10}":
            return [.key(.controlP)]
        case "\r", "\n":
            return [.key(.enter)]
        case "\u{1B}":
            return [.key(.escape)]
        case "\t":
            return [.key(.tab)]
        case "\u{7F}":
            return [.key(.backspace)]
        case "\u{1B}[A":
            return [.key(.up)]
        case "\u{1B}[B":
            return [.key(.down)]
        case "\u{1B}[C":
            return [.key(.right)]
        case "\u{1B}[D":
            return [.key(.left)]
        case "\u{1B}OA":
            return [.key(.up)]
        case "\u{1B}OB":
            return [.key(.down)]
        case "\u{1B}OC":
            return [.key(.right)]
        case "\u{1B}OD":
            return [.key(.left)]
        default:
            if text.count == 1, let character = text.first {
                return [.key(.character(character))]
            }
            return [.key(.unknown(text))]
        }
    }

    private func parseSGRMouse(_ text: String) -> MouseEvent? {
        guard text.hasPrefix("\u{1B}[<"), let suffix = text.last, suffix == "M" || suffix == "m" else {
            return nil
        }

        let body = text.dropFirst(3).dropLast()
        let parts = body.split(separator: ";")
        guard parts.count == 3,
              let code = Int(parts[0]),
              let column = Int(parts[1]),
              let row = Int(parts[2])
        else {
            return nil
        }

        return MouseEvent(
            button: mouseButton(from: code),
            location: Point(x: max(0, column - 1), y: max(0, row - 1)),
            pressed: suffix == "M"
        )
    }

    private func mouseButton(from code: Int) -> MouseButton {
        if code == 64 { return .scrollUp }
        if code == 65 { return .scrollDown }

        switch code & 0b11 {
        case 0:
            return .left
        case 1:
            return .middle
        case 2:
            return .right
        case 3:
            return .release
        default:
            return .unknown(code)
        }
    }

    private func parseArrowPrefix(_ text: Substring) -> (key: Key, length: Int)? {
        let variants: [(String, Key)] = [
            ("\u{1B}[A", .up),
            ("\u{1B}[B", .down),
            ("\u{1B}[C", .right),
            ("\u{1B}[D", .left),
            ("\u{1B}OA", .up),
            ("\u{1B}OB", .down),
            ("\u{1B}OC", .right),
            ("\u{1B}OD", .left)
        ]

        for (sequence, key) in variants where text.hasPrefix(sequence) {
            return (key, sequence.count)
        }

        guard text.hasPrefix("\u{1B}[") else { return nil }
        var length = 2
        var scan = text.index(text.startIndex, offsetBy: 2)
        while scan < text.endIndex {
            let character = text[scan]
            length += 1
            switch character {
            case "A":
                return (.up, length)
            case "B":
                return (.down, length)
            case "C":
                return (.right, length)
            case "D":
                return (.left, length)
            default:
                scan = text.index(after: scan)
            }
        }
        return nil
    }
}
