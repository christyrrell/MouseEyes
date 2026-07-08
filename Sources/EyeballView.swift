import Cocoa

class EyeballView: NSView {
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
}
