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

### v1.2: Back to NSStatusItem — the Replicant Discovery

The floating-window approach worked but required ever-growing heuristics to avoid
overlapping other menubar icons (hardcoded offsets, then a CGWindowList scan for
the leftmost status item). The overlap problem is unsolvable from outside the
menubar: only a real `NSStatusItem` gets space *reserved* for it.

Re-investigating the original mirroring blocker revealed how it actually works:

- AppKit creates **one `NSStatusBarWindow` per display** for a status item, all
  owned by our process and visible in `NSApp.windows`.
- One window hosts the real `NSStatusBarButton`; each other display's window
  hosts an `NSStatusItemReplicantView` containing an image view that mirrors the
  button window's rendered content. That is why a custom button view shows
  identical pixels on every display — but the replicant windows themselves are
  ordinary local windows we can add views to.

**Solution**: draw nothing in the button (a transparent placeholder image
reserves the item's width — an empty button collapses to zero), and attach an
independent `EyeballView` on top of each status bar window's `contentView`.
Each view computes its angle from its own window's screen position, restoring
true per-monitor tracking *inside* a real status item.

**Gotchas discovered**:
- The replicant image snapshots the entire real-button window — including the
  eyes we draw there. If the replicant hosting view ends up above our attached
  view (AppKit adds these on its own schedule, sometimes after we attach), that
  display shows a mirror of the other display's eyes. Fix: re-assert our view as
  the topmost subview (and give it a high layer `zPosition`) on every update.
- Status bar windows are created, destroyed, and reordered by AppKit at will
  (display changes, item repositioning), so attachment is re-checked on screen
  change notifications, on a 3s timer, and on every mouse update.
- New third-party items default to the far *left* of the icon area; on a notched
  MacBook with a crowded menubar that lands under the notch and macOS hides the
  item (its window reports `occluded`). Seeding
  `NSStatusItem Preferred Position <autosaveName>` in UserDefaults before
  creating the item requests a slot near the right edge on first launch;
  `autosaveName` persists later Cmd-drag repositioning.
- Clicks should open the item's menu natively on every display, so `EyeballView`
  overrides `hitTest` to return `nil`, letting events fall through to the button
  or replicant beneath.

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

### Why a Real NSStatusItem Wins (v1.2+)

**Floating window limitations** (v1.0–1.1 approach):
- The menubar doesn't know the windows exist, so other icons can be laid out
  underneath them — avoiding overlap required fragile positioning heuristics
- Notch avoidance, Cmd-drag repositioning, and menu behavior all reimplemented
  by hand

**Status item benefits**:
- The menubar reserves genuine space; overlap is impossible and other icons
  reflow around the eyes
- Native menu handling, drag-to-reposition with persistence, automatic layout
- Per-monitor rendering still achieved by attaching one `EyeballView` to each
  display's status bar window (see the Replicant Discovery section) — each has
  its own window and coordinate space, so per-monitor angle calculation works
  exactly as it did with floating windows

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
- Creates the `NSStatusItem` (fixed 60pt length, transparent placeholder image,
  native About/Quit menu, `autosaveName` for position persistence)
- Attaches an `EyeballView` to each display's status bar window and keeps it
  topmost (re-checked on screen changes, a timer, and every mouse update)
- Manages global mouse event monitoring and triggers redraws on all views

### EyeballView.swift
- Custom NSView subclass
- Calculates angle from its own window's screen position to mouse
- Draws eyeballs with Core Graphics
- Manages blink timer and animation
- `hitTest` returns nil so clicks reach the status item button natively

## Build System

**Xcode project** (`MouseEyes.xcodeproj`, migrated from Swift Package Manager in v1.1)
- `Info.plist`: Bundle configuration with `LSUIElement = true` (no Dock icon)
- Build: `xcodebuild -project MouseEyes.xcodeproj -scheme MouseEyes -configuration Release build`
- See `DISTRIBUTION.md` for archive/notarize/distribute steps

## Lessons Learned

1. **NSStatusItem mirroring is a replicant, not magic**: The mirrored copies are real windows in your own process — you can attach per-display views to them
2. **macOS coordinate system is global**: All screens share one coordinate space
3. **Menubar real estate is precious**: Only a real status item gets space reserved; floating windows over the menubar can always be overlapped
4. **Verify per-display behavior empirically**: Screenshots + a known cursor position caught the replicant image painting over our attached view
5. **Floating windows at statusBar level** (v1.0–1.1): Workable, but positioning heuristics fight a losing battle against other menubar apps

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
