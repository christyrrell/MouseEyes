import Cocoa

enum EyeStyle: String {
    case googly
    case sauron
}

class EyeballView: NSView {
    var style: EyeStyle = .googly {
        didSet {
            if oldValue != style {
                needsDisplay = true
            }
        }
    }

    private var isBlinking = false
    private var blinkTimer: Timer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        startBlinkTimer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func triggerUpdate() {
        self.needsDisplay = true
    }

    // Pass clicks through to the status item button (or its replicant on
    // secondary displays) underneath, so the menu opens natively everywhere.
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

    private func startBlinkTimer() {
        // Schedule random blinks every 3-6 seconds
        scheduleNextBlink()
    }

    private func scheduleNextBlink() {
        let randomInterval = Double.random(in: 3.0...6.0)
        blinkTimer?.invalidate()
        blinkTimer = Timer.scheduledTimer(withTimeInterval: randomInterval, repeats: false) { [weak self] _ in
            self?.performBlink()
        }
    }

    private func performBlink() {
        // Close eyes
        isBlinking = true
        self.needsDisplay = true

        // Open eyes after 150ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.isBlinking = false
            self?.needsDisplay = true
            self?.scheduleNextBlink()
        }
    }

    deinit {
        blinkTimer?.invalidate()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Calculate angle and distance from THIS window's position to the mouse
        var pupilAngle: CGFloat = 0
        var pupilDistance: CGFloat = 0

        // Get mouse location in screen coordinates
        let mouseLocation = NSEvent.mouseLocation

        // Calculate angle from THIS view's position to mouse
        if let window = self.window {
            // Get this view's center position in screen coordinates
            let viewRectInWindow = self.convert(self.bounds, to: nil)
            let viewFrameInScreen = window.convertToScreen(viewRectInWindow)
            let viewCenter = CGPoint(
                x: viewFrameInScreen.midX,
                y: viewFrameInScreen.midY
            )

            // Calculate angle from this eyeball to mouse
            let dx = mouseLocation.x - viewCenter.x
            let dy = mouseLocation.y - viewCenter.y
            pupilAngle = atan2(dy, dx)
            pupilDistance = min(sqrt(dx * dx + dy * dy) / 100.0, 1.0)
        }

        if style == .sauron {
            // The Lidless Eye does not blink
            drawSauronEye(context: context, angle: pupilAngle, distance: pupilDistance)
            return
        }

        // Draw two eyeballs side by side
        let eyeSpacing: CGFloat = 6
        let eyeSize: CGFloat = 16
        let pupilSize: CGFloat = 6
        let maxPupilOffset: CGFloat = 3.5

        let leftEyeX = bounds.midX - eyeSize - eyeSpacing / 2
        let rightEyeX = bounds.midX + eyeSpacing / 2
        let eyeY = bounds.midY - eyeSize / 2

        // Helper function to draw a single eye
        func drawEye(at origin: CGPoint) {
            if isBlinking {
                // Draw closed eye with visible eyelids
                let centerY = origin.y + eyeSize / 2

                // Draw upper eyelid (curved down)
                let upperPath = NSBezierPath()
                upperPath.move(to: CGPoint(x: origin.x + 2, y: centerY))
                let upperControl = CGPoint(x: origin.x + eyeSize / 2, y: centerY - 3)
                upperPath.curve(to: CGPoint(x: origin.x + eyeSize - 2, y: centerY),
                              controlPoint1: upperControl,
                              controlPoint2: upperControl)

                context.setStrokeColor(NSColor.black.cgColor)
                context.setLineWidth(2.0)
                context.setLineCap(.round)

                context.addPath(upperPath.cgPath)
                context.strokePath()
            } else {
                // Draw white of eye
                context.setFillColor(NSColor.white.cgColor)
                let eyeRect = CGRect(x: origin.x, y: origin.y, width: eyeSize, height: eyeSize)
                context.fillEllipse(in: eyeRect)

                // Draw eye outline
                context.setStrokeColor(NSColor.black.cgColor)
                context.setLineWidth(1.0)
                context.strokeEllipse(in: eyeRect)

                // Calculate pupil position based on angle and distance
                let pupilOffsetX = cos(pupilAngle) * maxPupilOffset * pupilDistance
                let pupilOffsetY = sin(pupilAngle) * maxPupilOffset * pupilDistance

                let pupilX = origin.x + eyeSize / 2 - pupilSize / 2 + pupilOffsetX
                let pupilY = origin.y + eyeSize / 2 - pupilSize / 2 + pupilOffsetY

                // Draw pupil (iris + pupil)
                context.setFillColor(NSColor.systemBlue.cgColor)
                let irisRect = CGRect(x: pupilX - 1, y: pupilY - 1,
                                    width: pupilSize + 2, height: pupilSize + 2)
                context.fillEllipse(in: irisRect)

                context.setFillColor(NSColor.black.cgColor)
                let pupilRect = CGRect(x: pupilX, y: pupilY, width: pupilSize, height: pupilSize)
                context.fillEllipse(in: pupilRect)

                // Add a highlight for realism
                context.setFillColor(NSColor.white.withAlphaComponent(0.7).cgColor)
                let highlightRect = CGRect(x: pupilX + 1, y: pupilY + 3, width: 2, height: 2)
                context.fillEllipse(in: highlightRect)
            }
        }

        // Draw both eyes
        drawEye(at: CGPoint(x: leftEyeX, y: eyeY))
        drawEye(at: CGPoint(x: rightEyeX, y: eyeY))
    }

    /// A single fiery almond-shaped eye with a vertical slit pupil.
    private func drawSauronEye(context: CGContext, angle: CGFloat, distance: CGFloat) {
        let eyeWidth: CGFloat = 46
        // Quad-curve control point offset; the almond's actual height is half this
        let lidCurve: CGFloat = 18
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let leftPoint = CGPoint(x: center.x - eyeWidth / 2, y: center.y)
        let rightPoint = CGPoint(x: center.x + eyeWidth / 2, y: center.y)

        let almond = CGMutablePath()
        almond.move(to: leftPoint)
        almond.addQuadCurve(to: rightPoint, control: CGPoint(x: center.x, y: center.y + lidCurve))
        almond.addQuadCurve(to: leftPoint, control: CGPoint(x: center.x, y: center.y - lidCurve))
        almond.closeSubpath()

        // The slit roams the almond; mostly horizontally, given the eye's shape
        let maxSlitOffsetX = eyeWidth / 2 - 9
        let maxSlitOffsetY: CGFloat = 1.5
        let slitCenter = CGPoint(
            x: center.x + cos(angle) * maxSlitOffsetX * distance,
            y: center.y + sin(angle) * maxSlitOffsetY * distance
        )

        // Fire gradient radiating from the slit, clipped to the almond
        context.saveGState()
        context.addPath(almond)
        context.clip()
        let fireColors = [
            NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.45, alpha: 1).cgColor,
            NSColor(calibratedRed: 1.0, green: 0.6, blue: 0.1, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.85, green: 0.2, blue: 0.0, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.35, green: 0.02, blue: 0.0, alpha: 1).cgColor,
        ] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: fireColors, locations: [0.0, 0.35, 0.7, 1.0]) {
            context.drawRadialGradient(
                gradient,
                startCenter: slitCenter, startRadius: 0,
                endCenter: slitCenter, endRadius: eyeWidth * 0.55,
                options: .drawsAfterEndLocation
            )
        }

        // Vertical cat-eye slit pupil (drawn inside the almond clip)
        let slitHeight: CGFloat = 13
        let slitCurve: CGFloat = 5  // control offset; actual slit width is half this
        let slitTop = CGPoint(x: slitCenter.x, y: slitCenter.y + slitHeight / 2)
        let slitBottom = CGPoint(x: slitCenter.x, y: slitCenter.y - slitHeight / 2)
        let slit = CGMutablePath()
        slit.move(to: slitTop)
        slit.addQuadCurve(to: slitBottom, control: CGPoint(x: slitCenter.x + slitCurve, y: slitCenter.y))
        slit.addQuadCurve(to: slitTop, control: CGPoint(x: slitCenter.x - slitCurve, y: slitCenter.y))
        slit.closeSubpath()
        context.addPath(slit)
        context.setFillColor(NSColor.black.cgColor)
        context.fillPath()

        // Feather the rim: still clipped to the almond, erase with progressively
        // narrower strokes centered on the edge so the flame's alpha ramps out
        // smoothly instead of ending in a hard border.
        context.setBlendMode(.destinationOut)
        for (width, alpha) in [(6.0, 0.25), (4.5, 0.3), (3.0, 0.4), (1.8, 0.55), (1.0, 0.7)] {
            context.addPath(almond)
            context.setStrokeColor(CGColor(gray: 0, alpha: alpha))
            context.setLineWidth(width)
            context.strokePath()
        }
        context.restoreGState()

        // Soft glow painted BEHIND the feathered flame (destinationOver fills
        // wherever the eye is translucent), so the faded rim dissolves into a
        // blurred halo rather than meeting the menubar directly. The shape is
        // drawn far off-canvas; only its blurred shadow lands on screen.
        context.saveGState()
        context.setBlendMode(.destinationOver)
        context.setShadow(offset: CGSize(width: 0, height: -600), blur: 6,
                          color: NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.02, alpha: 0.85).cgColor)
        context.translateBy(x: 0, y: 600)
        context.addPath(almond)
        context.setFillColor(NSColor.black.cgColor)
        context.fillPath()
        context.restoreGState()
    }
}
