import AppKit
import SwiftUI

struct ShortcutRecorder: NSViewRepresentable {
    @Binding var shortcut: Shortcut
    var onRecordingChanged: ((Bool) -> Void)? = nil

    func makeNSView(context: Context) -> RecorderField {
        let field = RecorderField()
        field.placeholderString = "点击后按快捷键"
        field.currentShortcut = shortcut
        field.onShortcutRecorded = { newShortcut in
            shortcut = newShortcut
        }
        field.onRecordingChanged = onRecordingChanged
        return field
    }

    func updateNSView(_ nsView: RecorderField, context: Context) {
        nsView.currentShortcut = shortcut
        nsView.onRecordingChanged = onRecordingChanged
    }
}

final class RecorderField: NSTextField {
    var currentShortcut: Shortcut = .default {
        didSet {
            if !isRecording {
                updateDisplay()
            }
        }
    }

    var onShortcutRecorded: ((Shortcut) -> Void)?
    var onRecordingChanged: ((Bool) -> Void)?
    private var isArmed = false
    private var isRecording = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        isEditable = false
        isSelectable = false
        isBordered = true
        isBezeled = true
        bezelStyle = .roundedBezel
        focusRingType = .default
        alignment = .center
        font = .systemFont(ofSize: 13, weight: .medium)
        backgroundColor = .textBackgroundColor
        drawsBackground = true
        updateDisplay()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { isArmed }

    override func becomeFirstResponder() -> Bool {
        let accepted = super.becomeFirstResponder()
        if accepted && isArmed {
            isRecording = true
            onRecordingChanged?(true)
            stringValue = "按下新的快捷键"
        }
        return accepted
    }

    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if resigned {
            isArmed = false
            if isRecording {
                onRecordingChanged?(false)
            }
            isRecording = false
            updateDisplay()
        }
        return resigned
    }

    override func mouseDown(with event: NSEvent) {
        isArmed = true
        window?.makeFirstResponder(self)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isRecording else { return false }
        return handle(event: event)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        _ = handle(event: event)
    }

    private func handle(event: NSEvent) -> Bool {
        if event.keyCode == 53 {
            window?.makeFirstResponder(nil)
            return true
        }

        guard let shortcut = Shortcut.from(event: event) else {
            NSSound.beep()
            return true
        }

        currentShortcut = shortcut
        onShortcutRecorded?(shortcut)
        window?.makeFirstResponder(nil)
        return true
    }

    private func updateDisplay() {
        stringValue = "当前：\(currentShortcut.displayString)"
    }
}
