// Screenshot renderer: compiled together with Sources/EyeballView.swift by make.sh.
import Cocoa
// Usage: render <googly|sauron> <angleDegrees> <scale> <out.png>
// Renders the app's real EyeballView looking along the given angle (0 = right,
// 90 = up) by placing its window so the current cursor lies in that direction.
let args = CommandLine.arguments
let style = EyeStyle(rawValue: args[1])!
let angle = Double(args[2])! * .pi / 180
let scale = Int(args[3])!
_ = NSApplication.shared
let size = NSSize(width: 60, height: 24)
let view = EyeballView(frame: NSRect(origin: .zero, size: size))
view.style = style
let mouse = NSEvent.mouseLocation
let center = NSPoint(x: mouse.x - cos(angle) * 400, y: mouse.y - sin(angle) * 400)
let window = NSWindow(contentRect: NSRect(x: center.x - size.width / 2, y: center.y - size.height / 2,
                                          width: size.width, height: size.height),
                      styleMask: .borderless, backing: .buffered, defer: true)
window.contentView = view
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width) * scale,
                           pixelsHigh: Int(size.height) * scale, bitsPerSample: 8, samplesPerPixel: 4,
                           hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = size
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
view.draw(view.bounds)
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[4]))
