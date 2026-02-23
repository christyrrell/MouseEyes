import Cocoa
import CoreGraphics

class AppDelegate: NSObject, NSApplicationDelegate {
    var eyeballWindows: [EyeballWindow] = []
    var mouseMonitor: Any?
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create eyeball windows for each screen
        createEyeballWindows()

        // Watch for screen changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // Start tracking mouse globally
        startMouseTracking()
    }

    func createEyeballWindows() {
        // Remove old windows
        eyeballWindows.forEach { $0.close() }
        eyeballWindows.removeAll()

        // Create a window for each screen
        print("Creating windows for \(NSScreen.screens.count) screens")
        for (index, screen) in NSScreen.screens.enumerated() {
            print("Screen \(index): frame = \(screen.frame)")
            let window = EyeballWindow(screen: screen)
            eyeballWindows.append(window)
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
            print("  Window created at: \(window.frame)")
        }
        print("Total windows created: \(eyeballWindows.count)")
    }

    @objc func screensDidChange() {
        // Recreate windows when screen configuration changes
        createEyeballWindows()
    }

    func startMouseTracking() {
        // Monitor global mouse moves
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.updateEyeballDirection()
        }

        // Also monitor local mouse moves (when mouse is over the app)
        NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.updateEyeballDirection()
            return event
        }

        // Initial update
        updateEyeballDirection()
    }

    func updateEyeballDirection() {
        // Trigger a redraw on all eyeball windows
        eyeballWindows.forEach { $0.eyeballView.triggerUpdate() }
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "MouseEyes"
        alert.informativeText = "A menubar app that watches your mouse cursor.\n\nVersion 1.0"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
