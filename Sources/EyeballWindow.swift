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
            xPosition = screen.frame.origin.x + auxiliaryTopLeftArea.width - windowWidth - 20
        } else {
            // No notch - dynamically find space to the left of status bar items
            if let leftEdge = Self.findLeftmostStatusItemX(on: screen) {
                xPosition = leftEdge - windowWidth - 8
            } else {
                // Fallback if detection fails
                xPosition = screen.frame.maxX - windowWidth - 200
            }
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
        let aboutItem = NSMenuItem(title: "About MouseEyes", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit MouseEyes", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
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

    /// Find the leftmost x-coordinate of status bar items on a given screen.
    /// Uses CGWindowListCopyWindowInfo to enumerate windows at the status bar level (layer 25).
    private static func findLeftmostStatusItemX(on screen: NSScreen) -> CGFloat? {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
        ) as? [[String: Any]] else {
            return nil
        }

        let myPID = ProcessInfo.processInfo.processIdentifier
        let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? 0

        // Convert screen's top edge to CG coordinates (CG origin is top-left, Cocoa is bottom-left)
        let screenTopCG = primaryScreenHeight - screen.frame.maxY
        let menubarMaxHeight: CGFloat = 30

        var leftmostX = screen.frame.maxX
        var foundAny = false

        for info in windowList {
            guard let layer = info[kCGWindowLayer as String] as? Int,
                  let pid = info[kCGWindowOwnerPID as String] as? Int32 else {
                continue
            }

            // Skip our own windows
            guard pid != myPID else { continue }

            // Only look at status bar level windows (layer 25)
            guard layer == 25 else { continue }

            // Parse window bounds
            guard let boundsDict = info[kCGWindowBounds as String] as? [String: Any] else { continue }
            var rect = CGRect.zero
            guard CGRectMakeWithDictionaryRepresentation(boundsDict as CFDictionary, &rect) else { continue }

            // Check if on this screen (by x range)
            guard rect.origin.x >= screen.frame.origin.x &&
                  rect.origin.x < screen.frame.maxX else { continue }

            // Check if in the menubar area (top of screen in CG coords)
            guard rect.origin.y >= screenTopCG &&
                  rect.origin.y < screenTopCG + menubarMaxHeight else { continue }

            leftmostX = min(leftmostX, rect.origin.x)
            foundAny = true
        }

        return foundAny ? leftmostX : nil
    }
}
