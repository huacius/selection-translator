import AppKit
import SwiftUI

@MainActor
final class ResultPanelController {
    private let panel: ResultPanel
    private let hostingView: NSHostingView<ResultPanelView>
    private var localMonitor: Any?
    private var globalMonitor: Any?

    init(appState: AppState) {
        let view = ResultPanelView(appState: appState)
        hostingView = NSHostingView(rootView: view)
        panel = ResultPanel(
            contentRect: NSRect(origin: .zero, size: NSSize(width: 430, height: 240)),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.onEscape = { [weak self] in
            self?.hide()
        }
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = true
        panel.isMovableByWindowBackground = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.contentView = hostingView
        installOutsideClickMonitors()
    }

    func show(near point: NSPoint? = nil) {
        let fittedSize = fittingPanelSize()
        panel.setContentSize(fittedSize)
        if let point {
            positionPanel(near: point, panelSize: fittedSize)
        } else {
            panel.center()
        }
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        panel.orderOut(nil)
    }
    private func installOutsideClickMonitors() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            self?.hideIfNeeded(for: event)
            return event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            guard let self, self.panel.isVisible else { return }
            let point = NSEvent.mouseLocation
            if !self.panel.frame.contains(point) {
                self.hide()
            }
        }
    }

    private func hideIfNeeded(for event: NSEvent) {
        guard panel.isVisible else { return }
        let point: NSPoint
        if let eventWindow = event.window {
            point = eventWindow.convertPoint(toScreen: event.locationInWindow)
        } else {
            point = NSEvent.mouseLocation
        }
        if !panel.frame.contains(point) {
            hide()
        }
    }

    private func positionPanel(near point: NSPoint, panelSize: NSSize) {
        let screen = screenContaining(point) ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 80, y: 80, width: 1200, height: 800)
        let margin: CGFloat = 12

        var originX = point.x - 34
        originX = min(max(originX, visibleFrame.minX + margin), visibleFrame.maxX - panelSize.width - margin)

        let preferredBelowY = point.y - panelSize.height - 18
        let fallbackAboveY = point.y + 22
        let originY: CGFloat

        if preferredBelowY >= visibleFrame.minY + margin {
            originY = preferredBelowY
        } else if fallbackAboveY + panelSize.height <= visibleFrame.maxY - margin {
            originY = fallbackAboveY
        } else {
            originY = max(visibleFrame.minY + margin, min(visibleFrame.maxY - panelSize.height - margin, preferredBelowY))
        }

        panel.setFrame(NSRect(origin: NSPoint(x: originX, y: originY), size: panelSize), display: false)
    }

    private func screenContaining(_ point: NSPoint) -> NSScreen? {
        NSScreen.screens.first(where: { $0.frame.contains(point) })
    }

    private func fittingPanelSize() -> NSSize {
        hostingView.layoutSubtreeIfNeeded()
        let fitting = hostingView.fittingSize
        let width = min(max(fitting.width, 360), 430)
        let height = min(max(fitting.height, 150), 300)
        return NSSize(width: width, height: height)
    }
}

final class ResultPanel: NSPanel {
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }
}
