# Changelog

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
