// Generates app/icon.png — a rounded-square Envkeep mark (green key on dark).
// Run from the project root:  swift app/make-icon.swift
import Cocoa

let S = 1024.0
let img = NSImage(size: NSSize(width: S, height: S))
img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// Rounded-square background with a dark gradient.
let m = 76.0
let rect = CGRect(x: m, y: m, width: S - 2*m, height: S - 2*m)
ctx.addPath(CGPath(roundedRect: rect, cornerWidth: 224, cornerHeight: 224, transform: nil))
ctx.clip()
let bg = [NSColor(srgbRed: 0.078, green: 0.090, blue: 0.106, alpha: 1).cgColor,
          NSColor(srgbRed: 0.043, green: 0.055, blue: 0.071, alpha: 1).cgColor] as CFArray
let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: bg,
                      locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])
ctx.resetClip()

// Green key: round bow + stem with two teeth.
let green = NSColor(srgbRed: 0.498, green: 0.933, blue: 0.392, alpha: 1)
green.setFill()
green.setStroke()

let cx = S/2
let bowCx = cx
let bowCy = S/2 + 150
let bowR = 150.0
let ring = NSBezierPath(ovalIn: CGRect(x: bowCx - bowR, y: bowCy - bowR, width: bowR*2, height: bowR*2))
ring.lineWidth = 78
ring.stroke()

// Stem downward from the bow.
let stemW = 70.0
let stemTop = bowCy - bowR + 30
let stemBottom = S/2 - 330
let stem = NSBezierPath(rect: CGRect(x: cx - stemW/2, y: stemBottom, width: stemW, height: stemTop - stemBottom))
stem.fill()

// Two teeth on the right of the stem.
let tooth1 = NSBezierPath(rect: CGRect(x: cx + stemW/2, y: stemBottom + 30, width: 90, height: stemW))
tooth1.fill()
let tooth2 = NSBezierPath(rect: CGRect(x: cx + stemW/2, y: stemBottom + 150, width: 60, height: stemW))
tooth2.fill()

img.unlockFocus()

let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: "app/icon.png"))
print("wrote app/icon.png")
