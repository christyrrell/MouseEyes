# MouseEyes Development Notes

This document chronicles the development of MouseEyes, a macOS menubar app with animated eyeballs that independently track the mouse cursor across multiple monitors.

## Project Overview

**Goal**: Create a fun macOS menubar app where eyeballs follow the mouse cursor, with each monitor's eyeballs looking from their own perspective.

**Challenge**: Multi-monitor independent tracking proved more complex than initially anticipated due to macOS's menubar mirroring behavior.

## Development Journey

### Initial Approach: NSStatusItem

**Attempt**: Standard NSStatusItem with custom view
- Created an `NSStatusItem` with a custom `EyeballView`
- Implemented global mouse tracking with `NSEvent.addGlobalMonitorForEvents`
- Drew eyeballs using Core Graphics

**Problem Discovered**: All three monitors showed eyeballs pointing in the same direction.

**Root Cause**: NSStatusItem automatically mirrors across all menubars, but there's only ONE view instance and ONE window object shared across all displays. Each monitor renders the same view with the same calculated angle.

### Solution: Per-Screen Floating Windows

**Architecture Change**: Abandoned NSStatusItem mirroring in favor of creating independent floating windows for each screen.

**Implementation**:
```swift
// Create a window for each screen
for screen in NSScreen.screens {
    let window = EyeballWindow(screen: screen)
    window.level = .statusBar
    window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
}
```

**Key Properties**:
- `.statusBar` level: Float at menubar height
- `.canJoinAllSpaces`: Visible on all virtual desktops
- `.stationary`: Don't move during Exposé
- `.fullScreenAuxiliary`: Show alongside full-screen apps

## Technical Challenges & Solutions

### 1. Multi-Monitor Angle Calculation

**Challenge**: Each monitor needs to calculate angles from its own position.

**Solution**: Each `EyeballWindow` has its own `EyeballView` instance. During `draw()`, each view:
1. Gets global mouse position via `NSEvent.mouseLocation`
2. Converts its own frame to screen coordinates
3. Calculates angle using `atan2(dy, dx)` from its position to mouse

**Code**:
```swift
let viewRectInWindow = self.convert(self.bounds, to: nil)
let viewFrameInScreen = window.convertToScreen(viewRectInWindow)
let dx = mouseLocation.x - viewFrameInScreen.midX
let dy = mouseLocation.y - viewFrameInScreen.midY
let angle = atan2(dy, dx)
```

### 2. MacBook Pro Notch Avoidance

**Challenge**: Eyeballs drawn in notch area are invisible on MacBook Pro displays.

**Solution**: Detect notch via `NSScreen.auxiliaryTopLeftArea` and position windows accordingly:

```swift
if let auxiliaryTopLeftArea = screen.auxiliaryTopLeftArea {
    // Screen has notch - position in left auxiliary area
    xPosition = screen.frame.origin.x + auxiliaryTopLeftArea.width - windowWidth - 20
} else {
    // No notch - standard positioning from right edge
    xPosition = screen.frame.origin.x + screen.frame.width - windowWidth - 850
}
```

### 3. Menubar Icon Collision

**Challenge**: Eyeballs overlapped with system icons (Control Center, clock, weather) and third-party apps (SwiftMenu).

**Solution Evolution**:
- Started: 120px from right edge → overlapped Control Center
- Increased to: 300px → overlapped Bluetooth/User icons
- Increased to: 450px → overlapped weather widget
- Increased to: 600px → overlapped SwiftMenu
- Final: 850px from right edge → clear of most menubar apps

### 4. Blinking Animation

**Implementation**: Timer-based state toggle with curved eyelid drawing.

```swift
// Random blink intervals (3-6 seconds)
Timer.scheduledTimer(withTimeInterval: Double.random(in: 3.0...6.0)) { _ in
    self.isBlinking = true
    self.needsDisplay = true

    // Open eyes after 150ms
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        self.isBlinking = false
        self.needsDisplay = true
    }
}
```

**Drawing**: When blinking, draw curved Bézier path instead of full eyeballs.

### 5. Entry Point Naming

**Issue**: `Main.swift` (uppercase) caused compile errors.

**Solution**: Swift requires lowercase `main.swift` for files with top-level code:
```swift
// main.swift (lowercase!)
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

### 6. Window Initialization

**Issue**: NSWindow subclass initialization errors with stored properties.

**Solution**: Use convenience initializer calling designated initializer:
```swift
class EyeballWindow: NSWindow {
    private(set) var eyeballView: EyeballView!

    convenience init(screen: NSScreen) {
        self.init(contentRect: windowRect, styleMask: [.borderless], ...)
        eyeballView = EyeballView(...)
    }
}
```

## Architecture Insights

### Why Floating Windows Win

**NSStatusItem Limitations**:
- Single shared view across all menubars
- No way to detect which monitor is rendering
- `window.screen` returns same value for all renders

**Floating Window Benefits**:
- Independent window instance per screen
- Each has its own coordinate space
- True per-monitor angle calculation

### Coordinate System

macOS uses a unified coordinate space across all displays:
- Origin (0,0) at bottom-left of primary display
- Positive x extends right across monitors
- Positive y extends up

Example with 3 monitors (1920x1080 each):
- Monitor 1: x=0-1920
- Monitor 2: x=1920-3840
- Monitor 3: x=3840-5760

### Performance Considerations

**Mouse Event Frequency**: `mouseMoved` events fire very frequently (~100Hz+). The app:
1. Receives event in AppDelegate
2. Calls `triggerUpdate()` on all windows
3. Each window calls `needsDisplay = true`
4. AppKit batches redraws efficiently

**Optimization**: No heavy computation in event handler, just marking views dirty.

## Files & Responsibilities

### main.swift
Entry point. Creates NSApplication and AppDelegate.

### AppDelegate.swift
- Creates `EyeballWindow` for each screen
- Manages global mouse event monitoring
- Handles screen configuration changes
- Triggers redraws on all windows

### EyeballWindow.swift
- Borderless transparent window at `.statusBar` level
- Detects screen notch via `auxiliaryTopLeftArea`
- Positions appropriately per screen type
- Hosts `EyeballView` and provides right-click menu

### EyeballView.swift
- Custom NSView subclass
- Calculates angle from its screen position to mouse
- Draws eyeballs with Core Graphics
- Manages blink timer and animation

## Build System

**Swift Package Manager**: Chosen for simplicity
- `Package.swift`: Defines executable target
- `build.sh`: Compiles and creates `.app` bundle
- `Info.plist`: Bundle configuration with `LSUIElement = true` (no Dock icon)

## Lessons Learned

1. **NSStatusItem mirroring is a trap**: Appears to work until you need per-monitor state
2. **macOS coordinate system is global**: All screens share one coordinate space
3. **Notch detection is essential**: Modern MacBooks require special handling
4. **Menubar real estate is precious**: System + third-party apps consume 800+ pixels from right
5. **Floating windows at statusBar level**: Perfect for menubar-like UI without NSStatusItem constraints

## Future Enhancements

Potential improvements:
- [ ] Configurable positioning via preferences
- [ ] Different eye styles (colors, shapes)
- [ ] Adjustable blink frequency
- [ ] Multiple eyes per monitor
- [ ] Eye tracking history/trails
- [ ] Reactions to specific apps/windows

## Credits

Built with Claude Code (Sonnet 4.5) in December 2024.

Architecture evolved through iterative problem-solving:
- NSStatusItem → independent floating windows
- Fixed positioning → notch-aware adaptive positioning
- Simple tracking → per-monitor angle calculation
- Static eyes → animated blinking

The journey from "simple menubar app" to "sophisticated multi-monitor eye tracking system" demonstrates how seemingly simple features can have complex requirements in multi-display environments.
