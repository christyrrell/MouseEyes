# MouseEyes 👀

A macOS menubar app that displays animated eyeballs that follow your mouse cursor across multiple monitors. Each monitor gets its own set of eyeballs that independently track the mouse from their perspective, creating a fun and engaging desktop experience.

## Features

- **Independent Multi-Monitor Tracking**: Each display has its own eyeballs that look at the mouse from their unique position
- **MacBook Pro Notch Support**: Automatically detects and positions eyeballs to avoid the notch on MacBook Pro displays
- **Natural Blinking**: Eyes blink randomly every 3-6 seconds for a lifelike effect
- **Smart Positioning**: Automatically avoids menubar icons and system controls
- **Click-Through**: Eyeballs don't interfere with menubar functionality
- **Native Swift**: Built with native macOS APIs for optimal performance

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode Command Line Tools or Swift toolchain

## Building

1. Navigate to the project directory:
   ```bash
   cd MouseEyes
   ```

2. Run the build script:
   ```bash
   ./build.sh
   ```

3. The app bundle will be created in `build/MouseEyes.app`

## Installation

After building, you can:

1. **Run directly**:
   ```bash
   open build/MouseEyes.app
   ```

2. **Install to Applications folder**:
   ```bash
   cp -r build/MouseEyes.app /Applications/
   ```

## Permissions

On first launch, macOS may prompt you to grant accessibility permissions:

1. Open **System Settings**
2. Navigate to **Privacy & Security** → **Accessibility**
3. Add **MouseEyes** to the list of allowed apps

This permission is required for the app to monitor global mouse movements.

## Usage

Once running, you'll see a pair of eyeballs in the menubar on each of your displays. The pupils will follow your mouse cursor as you move it around, with each display's eyeballs tracking from their own perspective.

### Features in Action

- **Multi-Monitor Tracking**: Move your mouse to the center monitor, and the left monitor's eyeballs will look right while the right monitor's eyeballs look left
- **Blinking**: Watch for the occasional natural blink every few seconds
- **Notch Avoidance**: On MacBook Pro displays with notches, eyeballs appear to the left of the notch

### Menu Access

Right-click on any eyeball to access:
- **About MouseEyes**: View app information
- **Quit MouseEyes**: Exit the application

## Development

### Project Structure

```
MouseEyes/
├── Sources/
│   ├── main.swift           # App entry point
│   ├── AppDelegate.swift    # Main app logic and window management
│   ├── EyeballWindow.swift  # Floating window for each screen
│   └── EyeballView.swift    # Custom view for rendering and animating eyeballs
├── Package.swift            # Swift package manifest
├── Info.plist               # App bundle configuration
├── build.sh                 # Build script
└── README.md
```

### Architecture

**Per-Screen Floating Windows**: Unlike traditional menubar apps that mirror a single view across displays, MouseEyes creates independent floating windows for each screen. This enables true per-monitor tracking.

**Notch Detection**: Uses `NSScreen.auxiliaryTopLeftArea` to detect MacBook Pro displays with notches and positions windows in the safe area to the left of the notch.

**Independent Angle Calculation**: Each window calculates the angle from its own screen position to the mouse cursor during every draw cycle, enabling proper directional tracking.

### Key Technologies

- **AppKit**: macOS UI framework
- **Core Graphics**: 2D rendering for custom eyeball drawing with blinking animation
- **Swift Package Manager**: Build system and dependency management
- **NSEvent Global Monitoring**: System-wide mouse tracking with accessibility permissions

### How It Works

1. **Window Creation**: On launch, the app queries all connected screens and creates a borderless, transparent floating window for each at `.statusBar` level
2. **Screen Change Detection**: Listens for `NSApplication.didChangeScreenParametersNotification` to recreate windows when displays are added/removed
3. **Global Mouse Tracking**: Uses `NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved)` to track cursor position across all displays
4. **Per-Window Rendering**: Each window's `EyeballView` calculates the angle from its screen position to the global mouse position and renders pupils accordingly
5. **Blink Timer**: Each view maintains its own timer that triggers random blinks (150ms duration, 3-6 second intervals)

## Troubleshooting

### App doesn't track mouse movements
- Ensure you've granted Accessibility permissions in System Settings
- Try quitting and restarting the app after granting permissions

### Build fails
- Verify you have Swift installed: `swift --version`
- Ensure you're on macOS 13.0 or later: `sw_vers`

### Eyeballs not visible on a display
- On MacBook Pro with notch: Eyeballs appear to the left of the notch
- On external monitors: Eyeballs appear right of center (850px from right edge)
- If hidden behind menubar icons, they may overlap with third-party menubar apps

### Eyeballs all point the same direction
- This should not happen with the current architecture. If it does, try restarting the app
- Ensure you're running the latest version

## Technical Notes

### Why Not Use NSStatusItem?

NSStatusItem automatically mirrors across all menubars but shares a single view/window instance, making per-monitor angle calculation impossible. The floating window approach creates truly independent instances per screen.

### Positioning Strategy

- **Screens with notch**: `screen.auxiliaryTopLeftArea.width - 80` pixels from left edge
- **Screens without notch**: 850 pixels from right edge
- Both provide clearance from system and third-party menubar icons

## License

Feel free to use and modify this project as you wish!

## Credits

Built with Swift and ❤️ for macOS
