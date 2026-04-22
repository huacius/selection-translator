import AppKit
import SwiftUI

private let lightMenuCardBackground = Color(red: 0.93, green: 0.97, blue: 1.0)
private let lightMenuHeaderBackground = Color(red: 0.94, green: 0.97, blue: 1.0)
private let lightMenuPrimaryText = Color(red: 0.10, green: 0.10, blue: 0.11)
private let lightMenuSecondaryText = Color(red: 0.42, green: 0.45, blue: 0.50)
private let lightMenuChipBackground = Color.white.opacity(0.62)
private let darkMenuCardBackground = Color(red: 0.12, green: 0.12, blue: 0.13)
private let darkMenuHeaderBackground = Color(red: 0.18, green: 0.18, blue: 0.20)
private let darkMenuPrimaryText = Color.white
private let darkMenuSecondaryText = Color(red: 0.70, green: 0.72, blue: 0.76)
private let darkMenuChipBackground = Color.white.opacity(0.06)
private let menuInnerCornerRadius: CGFloat = 10
private let menuToastCornerRadius: CGFloat = 9
private let aboutCardCornerRadius: CGFloat = 10

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct SelectionTranslatorApp: App {
    static let settingsWindowID = "settings-window"
    static let favoritesWindowID = "favorites-window"
    static let aboutWindowID = "about-window"

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var appState: AppState

    init() {
        let settingsStore = SettingsStore()
        let appState = AppState(settingsStore: settingsStore)
        appState.start()
        _settingsStore = StateObject(wrappedValue: settingsStore)
        _appState = StateObject(wrappedValue: appState)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(appState: appState, settingsStore: settingsStore)
        } label: {
            Image(systemName: "translate")
        }
        .menuBarExtraStyle(.window)

        Window("Settings", id: Self.settingsWindowID) {
            SettingsView(appState: appState, settingsStore: settingsStore) {
                appState.registerHotkey()
            }
        }
        .defaultSize(width: 640, height: 700)

        Window("Favorites", id: Self.favoritesWindowID) {
            FavoritesView(appState: appState)
        }
        .defaultSize(width: 460, height: 560)

        Window("About", id: Self.aboutWindowID) {
            AboutView()
        }
        .defaultSize(width: 420, height: 320)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

private struct MenuContentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme
    private let permissionRefreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @ObservedObject var appState: AppState
    @ObservedObject var settingsStore: SettingsStore

    private var menuCardBackground: Color {
        colorScheme == .dark ? darkMenuCardBackground : lightMenuCardBackground
    }

    private var menuHeaderBackground: Color {
        colorScheme == .dark ? darkMenuHeaderBackground : lightMenuHeaderBackground
    }

    private var menuPrimaryText: Color {
        colorScheme == .dark ? darkMenuPrimaryText : lightMenuPrimaryText
    }

    private var menuSecondaryText: Color {
        colorScheme == .dark ? darkMenuSecondaryText : lightMenuSecondaryText
    }

    private var menuChipBackground: Color {
        colorScheme == .dark ? darkMenuChipBackground : lightMenuChipBackground
    }

    private var appVersionText: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 9) {
                        AppIconBadge(size: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("划词翻译")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(menuPrimaryText)
                            Text("选中文本后按 \(settingsStore.settings.shortcut.displayString)")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(menuSecondaryText)
                        }
                        Spacer()
                    }

                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: menuInnerCornerRadius, style: .continuous)
                        .fill(menuHeaderBackground)
                )

                VStack(spacing: 9) {
                    primaryActionButton

                    HStack(spacing: 8) {
                        permissionChip
                        statusChip(
                            title: "目标语言",
                            value: settingsStore.settings.targetLanguage,
                            isGood: true
                        )
                    }
                }

                Divider()
                    .overlay(menuSecondaryText.opacity(colorScheme == .dark ? 0.18 : 0.10))

                VStack(spacing: 4) {
                    menuRow(title: "设置", systemName: "slider.horizontal.3") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            NSApp.activate(ignoringOtherApps: true)
                            openWindow(id: SelectionTranslatorApp.settingsWindowID)
                        }
                    }

                    menuRow(title: "查看收藏", systemName: "star") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            NSApp.activate(ignoringOtherApps: true)
                            openWindow(id: SelectionTranslatorApp.favoritesWindowID)
                        }
                    }

                    menuRow(title: "关于", systemName: "info.circle") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            NSApp.activate(ignoringOtherApps: true)
                            openWindow(id: SelectionTranslatorApp.aboutWindowID)
                        }
                    }

                    menuRow(title: "清除缓存", systemName: "trash") {
                        appState.clearCache()
                    }

                    menuRow(title: "重置授权", systemName: "lock.rotation") {
                        appState.resetAccessibilityPermission()
                    }

                    menuRow(title: "退出", systemName: "power") {
                        dismiss()
                        NSApp.terminate(nil)
                    }
                }

                HStack {
                    Spacer()
                    Text("v\(appVersionText)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(menuSecondaryText)
                }
            }
            .padding(12)
            .frame(width: 286)
            .background(menuCardBackground)

            if let menuToastMessage = appState.menuToastMessage {
                MenuToastView(message: menuToastMessage)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.18), value: appState.menuToastMessage)
        .onAppear {
            appState.refreshPermissionStatus()
        }
        .onReceive(permissionRefreshTimer) { _ in
            appState.refreshPermissionStatus()
        }
    }

    private var primaryActionButton: some View {
        Button {
            dismiss()
            Task {
                await appState.translateCurrentSelection()
            }
        } label: {
            HStack {
                Image(systemName: "text.viewfinder")
                    .font(.system(size: 12, weight: .medium))
                Text("翻译当前选中内容")
                    .font(.system(size: 13, weight: .regular))
                Spacer()
                if appState.isTranslating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
            }
            .foregroundStyle(menuPrimaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: menuInnerCornerRadius, style: .continuous)
                    .fill(menuChipBackground)
            )
        }
        .buttonStyle(.plain)
        .disabled(appState.isTranslating)
    }

    private var permissionChip: some View {
        Group {
            if appState.hasAccessibilityPermission {
                statusChip(
                    title: "权限",
                    value: "已开启",
                    isGood: true
                )
            } else {
                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        appState.requestAccessibilityAuthorization()
                    }
                } label: {
                    statusChip(
                        title: "权限",
                        value: "未开启",
                        isGood: false,
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func statusChip(title: String, value: String, isGood: Bool, showChevron: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 6) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(menuSecondaryText)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isGood ? Color.blue : Color.orange)
                            .frame(width: 6, height: 6)
                        Text(value)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(menuPrimaryText)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(menuSecondaryText.opacity(0.65))
                        .padding(.top, 2)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: menuInnerCornerRadius, style: .continuous)
                .fill(menuChipBackground)
        )
    }

    private func menuRow(title: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemName)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 16)
                    .foregroundStyle(Color.blue.opacity(0.85))
                Text(title)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(menuPrimaryText)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: menuInnerCornerRadius, style: .continuous)
                    .fill(menuChipBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AppIconBadge: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(Color(red: 0.965, green: 0.965, blue: 0.965))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                        .stroke(Color.black.opacity(0.10), lineWidth: max(1, size * 0.03))
                )

            Image(systemName: "translate")
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    Color(red: 0.04, green: 0.52, blue: 1.0),
                    Color.black.opacity(0.84)
                )
                .font(.system(size: size * 0.56, weight: .regular))
        }
        .frame(width: size, height: size)
    }
}

private struct AboutView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var appVersionText: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    private var pageBackground: Color {
        colorScheme == .dark ? Color(red: 0.15, green: 0.16, blue: 0.17) : Color(nsColor: .windowBackgroundColor)
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white
    }

    private var cardBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }

    var body: some View {
        VStack {
            VStack(spacing: 16) {
                AppIconBadge(size: 58)

                VStack(spacing: 6) {
                    Text("Selection Translator")
                        .font(.system(size: 22, weight: .bold))
                    Text("极简的 macOS 划词翻译工具")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text("Version \(appVersionText)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Text("面向英文阅读与学习场景，支持划词翻译、音标与发音。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 6) {
                    Link(destination: URL(string: "https://github.com/huacius/selection-translator")!) {
                        Text("GitHub · huacius/selection-translator")
                            .font(.system(size: 12, weight: .medium))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    Text("Any feedback: sengozhao@icloud.com")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: aboutCardCornerRadius, style: .continuous)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: aboutCardCornerRadius, style: .continuous)
                    .stroke(cardBorder, lineWidth: 0.8)
            )
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 320)
        .background(pageBackground)
    }
}

private struct MenuToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: menuToastCornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.82))
        )
    }
}

private struct MenuBarBubbleIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Color.white.opacity(0.97), lineWidth: 1.4)
                .frame(width: 18, height: 16)

            TriangleTail()
                .stroke(Color.white.opacity(0.97), lineWidth: 1.2)
                .frame(width: 6, height: 5)
                .offset(x: -3.6, y: 8.5)

            Text("译")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .offset(y: -0.5)
        }
        .frame(width: 20, height: 18)
    }
}

private struct TriangleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
