# MouseEyes 👀

A macOS menubar app that displays animated eyeballs that follow your mouse cursor across multiple monitors. Each monitor gets its own set of eyeballs that independently track the mouse from their perspective, creating a fun and engaging desktop experience.

## Features

- **Independent Multi-Monitor Tracking**: Each display has its own eyeballs that look at the mouse from their unique position
- **Real Menubar Item**: The eyes live in a genuine `NSStatusItem`, so macOS reserves space for them — they can never overlap another menubar icon, and can be repositioned with Cmd-drag
- **Natural Blinking**: Eyes blink randomly every 3-6 seconds for a lifelike effect
- **Eye of Sauron Mode**: Swap the googly eyes for a single fiery, lidless eye — its slit pupil still tracks your cursor from every display
- **Native Menu**: Click the eyes on any display for the app menu
- **Native Swift**: Built with native macOS APIs for optimal performance

## Requirements

- macOS 15.0 (Sequoia) or later
- Xcode

## Building

Build with Xcode (open `MouseEyes.xcodeproj`) or from the command line:

```bash
xcodebuild -project MouseEyes.xcodeproj -scheme MouseEyes -configuration Release build
```

See [DISTRIBUTION.md](DISTRIBUTION.md) for archiving, notarizing, and distributing.

## Installation

Copy the built `MouseEyes.app` to `/Applications` and open it.

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
- **Repositioning**: Hold Cmd and drag the eyes to move them anywhere in the menubar; the position is remembered

### Menu Access

Click (or right-click) the eyeballs on any display to access:
- **About MouseEyes**: View app information
- **Eye of Sauron**: Toggle between googly eyes and a single fiery eye (persists across launches)
- **Quit MouseEyes**: Exit the application

## Development

### Project Structure

```
MouseEyes/
├── Sources/
│   ├── main.swift           # App entry point
│   ├── AppDelegate.swift    # Status item, per-display view attachment, mouse tracking
│   └── EyeballView.swift    # Custom view for rendering and animating eyeballs
├── MouseEyes.xcodeproj      # Xcode project
├── Info.plist               # App bundle configuration
└── README.md
```

### Architecture

**Real NSStatusItem**: The eyes occupy a genuine status item, so the menubar lays other icons out around them — overlap is impossible and macOS handles notch avoidance, Cmd-drag repositioning, and menu behavior natively.

**Per-Display Views Inside the Status Item**: AppKit creates one status bar window per display for the item — one hosts the real `NSStatusBarButton`, the others host "replicant" views that mirror the button's rendered image (which is why a naive custom button view shows identical pixels on every display). MouseEyes attaches its own `EyeballView` to each of these windows, layered on top, so every display draws independently.

**Independent Angle Calculation**: Each view calculates the angle from its own window's screen position to the mouse cursor during every draw cycle, enabling proper directional tracking.

### Key Technologies

- **AppKit**: macOS UI framework
- **Core Graphics**: 2D rendering for custom eyeball drawing with blinking animation
- **NSEvent Global Monitoring**: System-wide mouse tracking with accessibility permissions

### How It Works

1. **Status Item Creation**: On launch, the app creates a fixed-width `NSStatusItem` with a transparent placeholder image (an empty button would collapse to zero width)
2. **View Attachment**: The app finds each display's status bar window and adds an `EyeballView` on top; it re-checks on screen changes, on a timer, and on every mouse update, since AppKit creates and reorders these windows on its own schedule
3. **Global Mouse Tracking**: Uses `NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved)` to track cursor position across all displays
4. **Per-View Rendering**: Each `EyeballView` calculates the angle from its window's screen position to the global mouse position and renders pupils accordingly
5. **Blink Timer**: Each view maintains its own timer that triggers random blinks (150ms duration, 3-6 second intervals)

## Troubleshooting

### App doesn't track mouse movements
- Ensure you've granted Accessibility permissions in System Settings
- Try quitting and restarting the app after granting permissions

### Build fails
- Verify Xcode is installed: `xcodebuild -version`
- Ensure you're on macOS 15.0 or later: `sw_vers`

### Eyeballs not visible on a display
- On a notched MacBook with a crowded menubar, an item too far from the right edge lands under the notch and macOS hides it — Cmd-drag the eyes further right
- On first launch the app requests a slot near the right end of the menubar to avoid this

### Eyeballs all point the same direction
- This should not happen with the current architecture. If it does, try restarting the app
- Ensure you're running the latest version

## Technical Notes

### The NSStatusItem Mirroring Problem

A custom view in a status item button renders identical pixels on every display: AppKit hosts the real button in one display's status bar window and shows a replicant image of it on the others, so per-monitor state can't be expressed through the button itself. MouseEyes works around this by drawing nothing in the button (a transparent placeholder reserves the width) and attaching its own view to each display's status bar window, above the button or replicant. Earlier versions instead floated borderless windows over the menubar, which required fragile heuristics to avoid overlapping other icons.

## License

Feel free to use and modify this project as you wish!

## Credits

Built with Swift and ❤️ for macOS
