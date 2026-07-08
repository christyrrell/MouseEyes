import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private static let statusItemLength: CGFloat = 60
    private static let autosaveName = "MouseEyes"
    private static let eyeStyleDefaultsKey = "EyeStyle"

    private var statusItem: NSStatusItem!
    private var sauronMenuItem: NSMenuItem!
    private var eyeballViews: [EyeballView] = []
    private var mouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var rescanTimer: Timer?

    private var eyeStyle: EyeStyle = .googly {
        didSet {
            UserDefaults.standard.set(eyeStyle.rawValue, forKey: Self.eyeStyleDefaultsKey)
            sauronMenuItem?.state = eyeStyle == .sauron ? .on : .off
            eyeballViews.forEach { $0.style = eyeStyle }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let raw = UserDefaults.standard.string(forKey: Self.eyeStyleDefaultsKey),
           let style = EyeStyle(rawValue: raw) {
            eyeStyle = style
        }
        seedPreferredPositionIfNeeded()
        createStatusItem()
        attachEyeballViews()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // AppKit creates and destroys the per-display status bar windows on its
        // own schedule (replicants can appear well after a display does), so
        // periodically re-attach in addition to reacting to screen changes.
        rescanTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.attachEyeballViews()
        }

        startMouseTracking()
    }

    /// On first launch, ask for a slot near the right end of the menubar. Third-party
    /// items default to the far left of the icon area, which on a notched MacBook
    /// with a crowded menubar lands under the notch and gets hidden. The user can
    /// still Cmd-drag the item anywhere; that position persists via autosaveName.
    private func seedPreferredPositionIfNeeded() {
        let key = "NSStatusItem Preferred Position \(Self.autosaveName)"
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(50, forKey: key)
        }
    }

    private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: Self.statusItemLength)
        statusItem.autosaveName = Self.autosaveName

        // A transparent placeholder keeps the button at full width (an empty
        // button collapses the item to zero). The eyes are drawn by EyeballViews
        // layered on top of each display's status bar window.
        statusItem.button?.image = NSImage(
            size: NSSize(width: Self.statusItemLength, height: 22),
            flipped: false
        ) { _ in true }

        let menu = NSMenu()
        let aboutItem = NSMenuItem(title: "About MouseEyes", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(.separator())
        sauronMenuItem = NSMenuItem(title: "Eye of Sauron", action: #selector(toggleSauron), keyEquivalent: "")
        sauronMenuItem.target = self
        sauronMenuItem.state = eyeStyle == .sauron ? .on : .off
        menu.addItem(sauronMenuItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit MouseEyes", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    /// AppKit gives this process one status bar window per display: one hosts the
    /// real NSStatusBarButton, the others host replicant views that mirror the
    /// button's rendered image (which is why a custom button view shows the same
    /// pixels on every display). Layering our own view into each window's
    /// contentView lets every display draw eyes from its own perspective.
    private func attachEyeballViews() {
        var views: [EyeballView] = []
        for window in NSApp.windows where window.className.contains("NSStatusBarWindow") {
            guard let contentView = window.contentView else { continue }
            let view: EyeballView
            if let existing = contentView.subviews.compactMap({ $0 as? EyeballView }).first {
                view = existing
            } else {
                view = EyeballView(frame: contentView.bounds)
                view.autoresizingMask = [.width, .height]
                contentView.addSubview(view)
            }
            view.style = eyeStyle
            // AppKit adds the button/replicant hosting views on its own schedule,
            // sometimes after ours. The replicant image snapshots the entire real
            // button window — including the eyes we drew there — so if it ends up
            // above our view, this display shows a mirror of another display's
            // eyes. Keep our view on top.
            view.layer?.zPosition = 1_000
            if contentView.subviews.last !== view {
                view.removeFromSuperview()
                contentView.addSubview(view)
            }
            views.append(view)
        }
        eyeballViews = views
    }

    @objc func screensDidChange() {
        attachEyeballViews()
        // Replicant windows for a newly attached display appear asynchronously
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.attachEyeballViews()
        }
    }

    func startMouseTracking() {
        // Monitor global mouse moves
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
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
        // Re-attach/re-order on every update: cheap (a handful of windows), and
        // catches AppKit recreating or reordering status bar window content.
        attachEyeballViews()
        eyeballViews.forEach { $0.triggerUpdate() }
    }

    @objc func toggleSauron() {
        eyeStyle = eyeStyle == .sauron ? .googly : .sauron
    }

    @objc func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "MouseEyes"
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        alert.informativeText = "A menubar app that watches your mouse cursor across all monitors.\n\nVersion \(version)"
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
        if let monitor = localMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        rescanTimer?.invalidate()
    }
}
