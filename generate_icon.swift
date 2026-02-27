#!/usr/bin/env swift
import Cocoa

func generateIcon(size: Int) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()

    let ctx = NSGraphicsContext.current!.cgContext
    let s = CGFloat(size)
    let rect = CGRect(x: 0, y: 0, width: s, height: s)

    // Background: rounded rect with Teams purple gradient
    let bgPath = CGPath(roundedRect: rect.insetBy(dx: s * 0.05, dy: s * 0.05),
                        cornerWidth: s * 0.22, cornerHeight: s * 0.22, transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    let colors = [
        CGColor(red: 0.35, green: 0.20, blue: 0.75, alpha: 1.0),
        CGColor(red: 0.50, green: 0.25, blue: 0.90, alpha: 1.0)
    ]
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                              colors: colors as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])
    ctx.resetClip()

    // Bell icon
    let bellCenterX = s * 0.5
    let bellCenterY = s * 0.52
    let bellScale = s * 0.28

    ctx.setFillColor(CGColor.white)

    // Bell body
    let bellBody = CGMutablePath()
    bellBody.move(to: CGPoint(x: bellCenterX - bellScale * 0.65, y: bellCenterY - bellScale * 0.4))
    bellBody.addQuadCurve(to: CGPoint(x: bellCenterX - bellScale * 0.5, y: bellCenterY + bellScale * 0.6),
                          control: CGPoint(x: bellCenterX - bellScale * 0.7, y: bellCenterY + bellScale * 0.1))
    bellBody.addQuadCurve(to: CGPoint(x: bellCenterX, y: bellCenterY + bellScale * 1.0),
                          control: CGPoint(x: bellCenterX - bellScale * 0.3, y: bellCenterY + bellScale * 1.0))
    bellBody.addQuadCurve(to: CGPoint(x: bellCenterX + bellScale * 0.5, y: bellCenterY + bellScale * 0.6),
                          control: CGPoint(x: bellCenterX + bellScale * 0.3, y: bellCenterY + bellScale * 1.0))
    bellBody.addQuadCurve(to: CGPoint(x: bellCenterX + bellScale * 0.65, y: bellCenterY - bellScale * 0.4),
                          control: CGPoint(x: bellCenterX + bellScale * 0.7, y: bellCenterY + bellScale * 0.1))
    bellBody.closeSubpath()
    ctx.addPath(bellBody)
    ctx.fillPath()

    // Bell top (dome)
    let domeRect = CGRect(x: bellCenterX - bellScale * 0.55,
                          y: bellCenterY - bellScale * 0.4 - bellScale * 0.6,
                          width: bellScale * 1.1, height: bellScale * 0.7)
    ctx.fillEllipse(in: domeRect)

    // Bell handle
    let handleRect = CGRect(x: bellCenterX - bellScale * 0.08,
                            y: bellCenterY - bellScale * 1.2,
                            width: bellScale * 0.16, height: bellScale * 0.35)
    ctx.fill(handleRect)

    // Bell bottom rim
    let rimRect = CGRect(x: bellCenterX - bellScale * 0.75,
                         y: bellCenterY + bellScale * 0.85,
                         width: bellScale * 1.5, height: bellScale * 0.18)
    ctx.addPath(CGPath(roundedRect: rimRect, cornerWidth: bellScale * 0.09,
                       cornerHeight: bellScale * 0.09, transform: nil))
    ctx.fillPath()

    // Bell clapper
    let clapperRect = CGRect(x: bellCenterX - bellScale * 0.15,
                             y: bellCenterY + bellScale * 1.0,
                             width: bellScale * 0.3, height: bellScale * 0.3)
    ctx.fillEllipse(in: clapperRect)

    // Alert badge (red dot, top-right)
    let badgeSize = s * 0.22
    let badgeRect = CGRect(x: s * 0.62, y: s * 0.62, width: badgeSize, height: badgeSize)
    ctx.setFillColor(CGColor(red: 1.0, green: 0.22, blue: 0.22, alpha: 1.0))
    ctx.fillEllipse(in: badgeRect)

    // Exclamation mark in badge
    ctx.setFillColor(CGColor.white)
    let excX = badgeRect.midX
    let excY = badgeRect.midY
    let excH = badgeSize * 0.22
    ctx.fill(CGRect(x: excX - excH * 0.25, y: excY - excH * 0.2,
                    width: excH * 0.5, height: excH * 1.6))
    ctx.fillEllipse(in: CGRect(x: excX - excH * 0.25, y: excY - excH * 0.9,
                                width: excH * 0.5, height: excH * 0.5))

    img.unlockFocus()
    return img
}

// Generate .iconset
let iconsetPath = "/Users/bap/IdeaProjects/teams-alert/TeamsAlert.iconset"
let fm = FileManager.default
try? fm.removeItem(atPath: iconsetPath)
try! fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024)
]

for (name, size) in sizes {
    let img = generateIcon(size: size)
    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { continue }
    let path = "\(iconsetPath)/\(name).png"
    try! png.write(to: URL(fileURLWithPath: path))
}
print("Iconset created at \(iconsetPath)")
