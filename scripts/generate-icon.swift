#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

func renderIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        fatalError("No graphics context")
    }

    let center = CGPoint(x: size / 2, y: size / 2)

    // --- Background: rounded rectangle with dark gradient ---
    let cornerRadius = size * 0.18
    let bgRect = CGRect(x: size * 0.02, y: size * 0.02,
                        width: size * 0.96, height: size * 0.96)
    let bgPath = CGPath(roundedRect: bgRect,
                        cornerWidth: cornerRadius, cornerHeight: cornerRadius,
                        transform: nil)

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    let bgColors = [
        CGColor(red: 0.10, green: 0.11, blue: 0.14, alpha: 1.0),
        CGColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1.0)
    ]
    let bgGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: bgColors as CFArray,
                                 locations: [0.0, 1.0])!
    ctx.drawLinearGradient(bgGradient,
                           start: CGPoint(x: 0, y: size),
                           end: CGPoint(x: size, y: 0),
                           options: [])
    ctx.restoreGState()

    // Clip all further drawing to the rounded rect
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    // --- DHD base: slightly tilted ellipse to give perspective ---
    let dhdRadiusX = size * 0.42
    let dhdRadiusY = size * 0.36
    let dhdCenter = CGPoint(x: center.x, y: center.y - size * 0.02)

    // --- Outer ring glow ---
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: size * 0.06,
                  color: CGColor(red: 0.4, green: 0.5, blue: 0.7, alpha: 0.3))
    ctx.setStrokeColor(CGColor(red: 0.35, green: 0.45, blue: 0.6, alpha: 0.4))
    ctx.setLineWidth(size * 0.02)
    ctx.addEllipse(in: CGRect(x: dhdCenter.x - dhdRadiusX, y: dhdCenter.y - dhdRadiusY,
                               width: dhdRadiusX * 2, height: dhdRadiusY * 2))
    ctx.strokePath()
    ctx.restoreGState()

    // --- DHD glyph segments (outer ring of "buttons") ---
    let numGlyphs = 19
    let glyphRadius = size * 0.34
    let glyphSize = size * 0.055

    // Usage percentage determines how many glyphs are "lit"
    let usageFraction: CGFloat = 0.72
    let litCount = Int(CGFloat(numGlyphs) * usageFraction)

    for i in 0..<numGlyphs {
        let angle = CGFloat(i) * (.pi * 2 / CGFloat(numGlyphs)) + .pi / 2
        let gx = dhdCenter.x + cos(angle) * glyphRadius * (dhdRadiusX / dhdRadiusX)
        let gy = dhdCenter.y + sin(angle) * glyphRadius * (dhdRadiusY / dhdRadiusX)

        let glyphRect = CGRect(x: gx - glyphSize, y: gy - glyphSize * 0.7,
                               width: glyphSize * 2, height: glyphSize * 1.4)
        let glyphPath = CGPath(roundedRect: glyphRect,
                               cornerWidth: glyphSize * 0.3, cornerHeight: glyphSize * 0.3,
                               transform: nil)

        if i < litCount {
            // Lit glyph — gradient from amber to coral based on position
            let t = CGFloat(i) / CGFloat(litCount)
            let r: CGFloat = 1.0
            let g: CGFloat = 0.75 - t * 0.45
            let b: CGFloat = 0.20 + t * 0.15

            // Glow
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: size * 0.025,
                          color: CGColor(red: r, green: g, blue: b, alpha: 0.7))
            ctx.setFillColor(CGColor(red: r, green: g, blue: b, alpha: 0.95))
            ctx.addPath(glyphPath)
            ctx.fillPath()
            ctx.restoreGState()
        } else {
            // Unlit glyph — dim
            ctx.saveGState()
            ctx.setFillColor(CGColor(red: 0.20, green: 0.22, blue: 0.26, alpha: 0.8))
            ctx.addPath(glyphPath)
            ctx.fillPath()
            // Subtle border
            ctx.setStrokeColor(CGColor(red: 0.30, green: 0.32, blue: 0.36, alpha: 0.5))
            ctx.setLineWidth(size * 0.004)
            ctx.addPath(glyphPath)
            ctx.strokePath()
            ctx.restoreGState()
        }
    }

    // --- Inner ring of smaller glyphs ---
    let innerGlyphs = 12
    let innerRadius = size * 0.21
    let innerGlyphSize = size * 0.04
    let innerLit = Int(CGFloat(innerGlyphs) * usageFraction)

    for i in 0..<innerGlyphs {
        let angle = CGFloat(i) * (.pi * 2 / CGFloat(innerGlyphs)) + .pi / 2
        let gx = dhdCenter.x + cos(angle) * innerRadius
        let gy = dhdCenter.y + sin(angle) * innerRadius * (dhdRadiusY / dhdRadiusX)

        let glyphRect = CGRect(x: gx - innerGlyphSize, y: gy - innerGlyphSize * 0.7,
                               width: innerGlyphSize * 2, height: innerGlyphSize * 1.4)
        let glyphPath = CGPath(roundedRect: glyphRect,
                               cornerWidth: innerGlyphSize * 0.3,
                               cornerHeight: innerGlyphSize * 0.3,
                               transform: nil)

        if i < innerLit {
            let t = CGFloat(i) / CGFloat(max(innerLit, 1))
            let r: CGFloat = 0.5 + t * 0.3
            let g: CGFloat = 0.7 - t * 0.3
            let b: CGFloat = 0.9 - t * 0.3

            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: size * 0.015,
                          color: CGColor(red: r, green: g, blue: b, alpha: 0.5))
            ctx.setFillColor(CGColor(red: r, green: g, blue: b, alpha: 0.85))
            ctx.addPath(glyphPath)
            ctx.fillPath()
            ctx.restoreGState()
        } else {
            ctx.saveGState()
            ctx.setFillColor(CGColor(red: 0.18, green: 0.20, blue: 0.24, alpha: 0.7))
            ctx.addPath(glyphPath)
            ctx.fillPath()
            ctx.restoreGState()
        }
    }

    // --- Center crystal (the big orange dome) ---
    let crystalRadius = size * 0.10
    let crystalCenter = dhdCenter

    // Crystal glow (large soft)
    ctx.saveGState()
    let glowColors = [
        CGColor(red: 1.0, green: 0.6, blue: 0.15, alpha: 0.5),
        CGColor(red: 1.0, green: 0.5, blue: 0.15, alpha: 0.0)
    ]
    let glowGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                   colors: glowColors as CFArray,
                                   locations: [0.0, 1.0])!
    ctx.drawRadialGradient(glowGradient,
                           startCenter: crystalCenter, startRadius: 0,
                           endCenter: crystalCenter, endRadius: crystalRadius * 2.5,
                           options: [])
    ctx.restoreGState()

    // Crystal body
    ctx.saveGState()
    let crystalColors = [
        CGColor(red: 1.0, green: 0.85, blue: 0.50, alpha: 1.0),
        CGColor(red: 1.0, green: 0.55, blue: 0.15, alpha: 1.0),
        CGColor(red: 0.85, green: 0.35, blue: 0.10, alpha: 1.0)
    ]
    let crystalGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: crystalColors as CFArray,
                                      locations: [0.0, 0.5, 1.0])!
    ctx.addEllipse(in: CGRect(x: crystalCenter.x - crystalRadius,
                               y: crystalCenter.y - crystalRadius * 0.85,
                               width: crystalRadius * 2, height: crystalRadius * 1.7))
    ctx.clip()
    ctx.drawRadialGradient(crystalGradient,
                           startCenter: CGPoint(x: crystalCenter.x - crystalRadius * 0.3,
                                                y: crystalCenter.y + crystalRadius * 0.3),
                           startRadius: 0,
                           endCenter: crystalCenter, endRadius: crystalRadius,
                           options: [.drawsAfterEndLocation])
    ctx.restoreGState()

    // Crystal highlight (specular)
    ctx.saveGState()
    let highlightCenter = CGPoint(x: crystalCenter.x - crystalRadius * 0.25,
                                  y: crystalCenter.y + crystalRadius * 0.25)
    let highlightColors = [
        CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.7),
        CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
    ]
    let highlightGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: highlightColors as CFArray,
                                        locations: [0.0, 1.0])!
    ctx.drawRadialGradient(highlightGradient,
                           startCenter: highlightCenter, startRadius: 0,
                           endCenter: highlightCenter, endRadius: crystalRadius * 0.5,
                           options: [])
    ctx.restoreGState()

    // --- Crystal border ring ---
    ctx.saveGState()
    ctx.setStrokeColor(CGColor(red: 0.75, green: 0.50, blue: 0.15, alpha: 0.6))
    ctx.setLineWidth(size * 0.006)
    ctx.addEllipse(in: CGRect(x: crystalCenter.x - crystalRadius,
                               y: crystalCenter.y - crystalRadius * 0.85,
                               width: crystalRadius * 2, height: crystalRadius * 1.7))
    ctx.strokePath()
    ctx.restoreGState()

    ctx.restoreGState() // End clip to bg rounded rect

    image.unlockFocus()
    return image
}

// Generate iconset
let iconsetPath = "build/AppIcon.iconset"
let fm = FileManager.default
try? fm.removeItem(atPath: iconsetPath)
try! fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for (name, size) in sizes {
    let image = renderIcon(size: size)
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to render \(name)")
        continue
    }
    let path = "\(iconsetPath)/\(name).png"
    try! png.write(to: URL(fileURLWithPath: path))
    print("Generated \(name) (\(Int(size))x\(Int(size)))")
}

print("\nIconset generated. Converting to icns...")
