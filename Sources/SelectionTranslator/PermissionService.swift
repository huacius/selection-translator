import AppKit
import ApplicationServices
import Foundation

enum PermissionService {
    private static let bundleIdentifier = "com.sengo.selectiontranslator"

    static func isAccessibilityEnabled() -> Bool {
        AXIsProcessTrusted()
    }

    static func promptAccessibilityIfNeeded() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    static func resetAccessibilityPermission() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        process.arguments = ["reset", "Accessibility", bundleIdentifier]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "PermissionService", code: Int(process.terminationStatus))
        }
    }
}
