import Cocoa

class EyeballWindow: NSWindow {
    private(set) var eyeballView: EyeballView!

    convenience init(screen: NSScreen) {
        // Position window in the menubar, avoiding notch and system icons
        let windowWidth: CGFloat = 60
        let windowHeight: CGFloat = 22

        var xPosition: CGFloat

        // Check if this screen has a notch (MacBook Pro built-in display)
        if let auxiliaryTopLeftArea = screen.auxiliaryTopLeftArea {
            // Screen has a notch - position in the left auxiliary area
            // Place near the right edge of the left auxiliary area
            xPosition = screen.frame.origin.x + auxiliaryTopLeftArea.width - windowWidth - 20
            print("Screen with notch detected - auxiliary left area width: \(auxiliaryTopLeftArea.width)")
        } else {
            // No notch - use standard positioning from right edge
            // Position away from system icons and third-party menubar apps
            let rightMargin: CGFloat = 850
            xPosition = screen.frame.origin.x + screen.frame.width - windowWidth - rightMargin
        }

        let windowRect = NSRect(
            x: xPosition,
            y: screen.frame.maxY - windowHeight,
            width: windowWidth,
            height: windowHeight
        )

        // Don't pass screen parameter - let window position itself by frame
        self.init(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // Create the eyeball view
        eyeballView = EyeballView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
        eyeballView.targetScreen = screen

        // Configure window to float at menubar level and be transparent
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .statusBar  // Same level as menubar
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        self.isMovable = false
        self.hidesOnDeactivate = false

        // Add the eyeball view
        self.contentView = eyeballView

        // Add right-click menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About MouseEyes", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit MouseEyes", action: #selector(quit), keyEquivalent: "q"))
        eyeballView.menu = menu
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "MouseEyes"
        alert.informativeText = "A menubar app that watches your mouse cursor across all monitors.\n\nVersion 1.0"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
