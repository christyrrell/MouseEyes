# Changelog

## 1.2 (2026-07-07)

### Added

- **Eye of Sauron mode**: Toggle "Eye of Sauron" in the menu to replace the googly eyes with a single fiery, lidless eye whose vertical slit pupil tracks the cursor (per monitor, of course). Movie-style shading: a dark ember interior lined with bright flame at the rim, feathering out through a soft glow rather than ending in a hard outline. The choice persists across launches.

### Changed

- **Native menubar item**: The eyes now live in a real `NSStatusItem` instead of floating windows overlaid on the menubar, so macOS reserves genuine space for them — they can never be drawn on top of another menubar icon, and other icons reflow around them. Per-monitor tracking is preserved by attaching an independent eyeball view to each display's status bar window (AppKit creates one per screen: the real button on one, a replicant that mirrors its image on the others — the mirroring that originally forced the floating-window approach).
- The menu now opens natively from the status item (left- or right-click) on any display.
- The item can be repositioned with Cmd-drag and the position persists. On first launch it asks for a slot near the right end of the menubar so it stays visible right of the notch on MacBook displays.
- Removed the CGWindowList-based heuristic that guessed where other status items were.

## 1.1 (2026-02-24)

### Fixed

- **Crash on display sleep/wake**: The app would crash with a segmentation fault (`EXC_BAD_ACCESS` in `_NSWindowTransformAnimation`) when screens powered off and back on overnight. Screen configuration changes triggered immediate window destruction while AppKit animations still held references to the old windows. Fixed by deferring old window teardown to the next run loop iteration, allowing in-flight Core Animation transactions to complete before windows are released.

## 1.0 (2024-12-01)

### Initial Release

- Animated eyeballs in the menubar that track the mouse cursor
- Independent per-monitor tracking with correct angle calculation
- MacBook Pro notch detection and avoidance
- Random blinking animation
- Automatic repositioning to avoid system and third-party menubar icons
- Works across all virtual desktops and alongside full-screen apps
