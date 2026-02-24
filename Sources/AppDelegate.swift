import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var eyeballWindows: [EyeballWindow] = []
    var mouseMonitor: Any?
    var localMouseMonitor: Any?

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
        let oldWindows = eyeballWindows
        eyeballWindows.removeAll()

        // Create a window for each screen
        for screen in NSScreen.screens {
            let window = EyeballWindow(screen: screen)
            eyeballWindows.append(window)
            window.orderFrontRegardless()
        }

        // Defer old window cleanup to let in-flight animations finish
        DispatchQueue.main.async {
            oldWindows.forEach { $0.orderOut(nil) }
        }
    }

    @objc func screensDidChange() {
        createEyeballWindows()
    }

    func startMouseTracking() {
        // Monitor global mouse moves
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.updateEyeballDirection()
        }

        // Also monitor local mouse moves (when mouse is over the app)
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
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

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
