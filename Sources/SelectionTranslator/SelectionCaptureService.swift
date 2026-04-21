import AppKit
import ApplicationServices
import Foundation

struct SelectionCaptureService {
    enum CaptureError: LocalizedError {
        case missingPermission
        case emptySelection

        var errorDescription: String? {
            switch self {
            case .missingPermission:
                return "需要在 macOS 的“辅助功能”里允许本应用控制键盘，才能抓取当前选中文本。"
            case .emptySelection:
                return "没有抓到当前选中的文本。"
            }
        }
    }

    func captureSelectedText() async throws -> String {
        guard PermissionService.promptAccessibilityIfNeeded() else {
            throw CaptureError.missingPermission
        }

        let pasteboard = NSPasteboard.general
        let snapshot = ClipboardSnapshot(pasteboard: pasteboard)
        let initialChangeCount = pasteboard.changeCount

        try simulateCopyShortcut()
        try await Task.sleep(for: .milliseconds(180))

        let updatedText = try readCopiedText(
            pasteboard: pasteboard,
            initialChangeCount: initialChangeCount
        )
        snapshot.restore(to: pasteboard)

        let trimmed = updatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CaptureError.emptySelection
        }
        return trimmed
    }

    private func simulateCopyShortcut() throws {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            throw CaptureError.emptySelection
        }

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }

    private func readCopiedText(pasteboard: NSPasteboard, initialChangeCount: Int) throws -> String {
        if pasteboard.changeCount == initialChangeCount, let current = pasteboard.string(forType: .string), !current.isEmpty {
            return current
        }

        if let copied = pasteboard.string(forType: .string), !copied.isEmpty {
            return copied
        }

        throw CaptureError.emptySelection
    }
}

private struct ClipboardSnapshot {
    private let items: [[NSPasteboard.PasteboardType: Data]]

    init(pasteboard: NSPasteboard) {
        items = pasteboard.pasteboardItems?.map { item in
            var values: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    values[type] = data
                }
            }
            return values
        } ?? []
    }

    func restore(to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        for item in items {
            let boardItem = NSPasteboardItem()
            for (type, data) in item {
                boardItem.setData(data, forType: type)
            }
            pasteboard.writeObjects([boardItem])
        }
    }
}
