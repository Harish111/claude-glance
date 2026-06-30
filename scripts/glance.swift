import AppKit

// claude-glance — a native floating traffic-light overlay for Claude Code.
// Reads ~/.claude/claude-glance/status (one word: red | yellow | green)
// and lights the matching lamp. Floats above all apps, on every Space, over
// fullscreen, without stealing focus. Drag to move. Double-click to quit.

let BASE = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".claude")
    .appendingPathComponent("claude-glance")
let STATE_FILE = BASE.appendingPathComponent("status")
let PID_FILE = BASE.appendingPathComponent("pid")

func readState() -> String {
    guard let s = try? String(contentsOf: STATE_FILE, encoding: .utf8) else { return "green" }
    let t = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return ["red", "yellow", "green"].contains(t) ? t : "green"
}

final class LightView: NSView {
    var state: String = "green" { didSet { if state != oldValue { needsDisplay = true } } }

    let bright: [String: NSColor] = [
        "red": NSColor(srgbRed: 1.00, green: 0.23, blue: 0.19, alpha: 1),
        "yellow": NSColor(srgbRed: 1.00, green: 0.80, blue: 0.00, alpha: 1),
        "green": NSColor(srgbRed: 0.20, green: 0.78, blue: 0.35, alpha: 1),
    ]
    let dim: [String: NSColor] = [
        "red": NSColor(srgbRed: 0.29, green: 0.09, blue: 0.08, alpha: 1),
        "yellow": NSColor(srgbRed: 0.29, green: 0.24, blue: 0.00, alpha: 1),
        "green": NSColor(srgbRed: 0.07, green: 0.24, blue: 0.11, alpha: 1),
    ]

    override func draw(_ dirtyRect: NSRect) {
        let b = bounds
        let housing = NSBezierPath(roundedRect: b, xRadius: 15, yRadius: 15)
        NSColor(srgbRed: 0.11, green: 0.11, blue: 0.12, alpha: 0.96).setFill()
        housing.fill()

        let r: CGFloat = 16
        let cx = b.midX
        let order = ["red", "yellow", "green"]
        let ys: [CGFloat] = [b.maxY - 34, b.midY, b.minY + 34]
        for (name, cy) in zip(order, ys) {
            if name == state {
                bright[name]!.withAlphaComponent(0.30).setFill()
                NSBezierPath(ovalIn: NSRect(x: cx - r - 5, y: cy - r - 5,
                                            width: 2 * r + 10, height: 2 * r + 10)).fill()
            }
            (name == state ? bright[name]! : dim[name]!).setFill()
            NSBezierPath(ovalIn: NSRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)).fill()
        }
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount >= 2 {
            try? FileManager.default.removeItem(at: PID_FILE)
            NSApp.terminate(nil)
        } else {
            super.mouseDown(with: event)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: NSPanel!
    var view: LightView!
    var timer: Timer?

    func applicationDidFinishLaunching(_ note: Notification) {
        let W: CGFloat = 58, H: CGFloat = 158
        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let rect = NSRect(x: screen.maxX - W - 24, y: screen.maxY - H - 44, width: W, height: H)

        panel = NSPanel(contentRect: rect,
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary,
                                    .fullScreenAuxiliary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false

        view = LightView(frame: NSRect(x: 0, y: 0, width: W, height: H))
        panel.contentView = view
        panel.orderFrontRegardless()
        view.state = readState()

        let t = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.view.state = readState()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
}

let pid = ProcessInfo.processInfo.processIdentifier
try? "\(pid)".write(to: PID_FILE, atomically: true, encoding: .utf8)

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
