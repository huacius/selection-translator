#!/usr/bin/env swift

import AppKit
import Foundation

let fileManager = FileManager.default
let root = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let buildDir = root.appendingPathComponent(".build/icon", isDirectory: true)
let iconsetURL = buildDir.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let icnsURL = buildDir.appendingPathComponent("AppIcon.icns")
let renderedDir = buildDir.appendingPathComponent("rendered", isDirectory: true)
let renderedSource = renderedDir.appendingPathComponent("app_icon_master.png")

try? fileManager.removeItem(at: iconsetURL)
try? fileManager.removeItem(at: icnsURL)
try? fileManager.removeItem(at: renderedDir)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
try fileManager.createDirectory(at: renderedDir, withIntermediateDirectories: true)

func run(_ executable: String, _ arguments: [String]) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = Pipe()
    process.standardError = Pipe()
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw NSError(domain: "IconGeneration", code: Int(process.terminationStatus))
    }
}

func makeMasterIcon(at url: URL) throws {
    let canvasSize = NSSize(width: 1024, height: 1024)
    let canvasRect = NSRect(origin: .zero, size: canvasSize)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasSize.width),
        pixelsHigh: Int(canvasSize.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "IconGeneration", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create bitmap context."])
    }
    bitmap.size = canvasSize

    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "IconGeneration", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to create graphics context."])
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    defer {
        NSGraphicsContext.restoreGraphicsState()
    }

    NSColor.clear.setFill()
    NSBezierPath(rect: canvasRect).fill()

    let backgroundRect = NSRect(x: 72, y: 72, width: 880, height: 880)
    let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: 190, yRadius: 190)

    NSGraphicsContext.current?.imageInterpolation = .high

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowBlurRadius = 28
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.18)
    shadow.set()

    NSColor(calibratedWhite: 0.965, alpha: 1).setFill()
    backgroundPath.fill()

    NSColor(calibratedWhite: 0.84, alpha: 1).setStroke()
    backgroundPath.lineWidth = 1.5
    backgroundPath.stroke()

    NSGraphicsContext.restoreGraphicsState()

    let baseConfiguration = NSImage.SymbolConfiguration(pointSize: 620, weight: .regular, scale: .large)
    let paletteConfiguration = NSImage.SymbolConfiguration(
        paletteColors: [
            NSColor(calibratedRed: 0.04, green: 0.52, blue: 1.0, alpha: 1.0),
            NSColor(calibratedWhite: 0.16, alpha: 1.0)
        ]
    )
    let symbolConfiguration = baseConfiguration.applying(paletteConfiguration)

    guard let symbol = NSImage(systemSymbolName: "translate", accessibilityDescription: nil)?
        .withSymbolConfiguration(symbolConfiguration) else {
        throw NSError(domain: "IconGeneration", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to load SF Symbol 'translate'."])
    }

    let symbolSize = NSSize(width: 620, height: 620)
    let symbolRect = NSRect(
        x: (canvasSize.width - symbolSize.width) / 2,
        y: (canvasSize.height - symbolSize.height) / 2 + 6,
        width: symbolSize.width,
        height: symbolSize.height
    )

    symbol.draw(in: symbolRect)

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGeneration", code: 5, userInfo: [NSLocalizedDescriptionKey: "Unable to encode app icon PNG."])
    }

    try pngData.write(to: url)
}

try makeMasterIcon(at: renderedSource)

guard fileManager.fileExists(atPath: renderedSource.path) else {
    fputs("Rendered PNG not produced at: \(renderedSource.path)\n", stderr)
    exit(1)
}

let outputs: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

for (size, filename) in outputs {
    let outputURL = iconsetURL.appendingPathComponent(filename)
    try run("/usr/bin/sips", [
        "-z", "\(size)", "\(size)",
        renderedSource.path,
        "--out", outputURL.path
    ])
}

try run("/usr/bin/iconutil", [
    "-c", "icns",
    iconsetURL.path,
    "-o", icnsURL.path
])

print(icnsURL.path)
