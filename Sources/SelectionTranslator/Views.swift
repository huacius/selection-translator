import SwiftUI

private let formSecondaryText = Color.secondary
private let panelCornerRadius: CGFloat = 12
private let panelInnerCornerRadius: CGFloat = 10
private let panelBadgeCornerRadius: CGFloat = 8
private let settingsCardCornerRadius: CGFloat = 10
private let settingsButtonCornerRadius: CGFloat = 8

struct ResultPanelView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var appState: AppState
    @State private var isOriginalExpanded = false

    private var isDarkMode: Bool { colorScheme == .dark }
    private var cardPrimaryText: Color { isDarkMode ? .white : Color(red: 0.10, green: 0.10, blue: 0.11) }
    private var cardSecondaryText: Color { isDarkMode ? Color(red: 0.72, green: 0.74, blue: 0.78) : Color(red: 0.45, green: 0.47, blue: 0.51) }
    private var cardMutedText: Color { isDarkMode ? Color(red: 0.60, green: 0.63, blue: 0.68) : Color(red: 0.67, green: 0.69, blue: 0.72) }
    private var cardSurface: Color { isDarkMode ? Color(red: 0.13, green: 0.13, blue: 0.14) : .white }
    private var cardSurfaceAccent: Color { isDarkMode ? Color(red: 0.15, green: 0.16, blue: 0.18) : Color(red: 0.992, green: 0.996, blue: 1.0) }
    private var cardSoftSurface: Color { isDarkMode ? Color.white.opacity(0.06) : Color(red: 0.98, green: 0.98, blue: 0.985) }
    private var cardBadgeBackground: Color { isDarkMode ? Color.white.opacity(0.08) : Color(red: 0.96, green: 0.97, blue: 0.99) }
    private var cardBorder: Color { isDarkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.09) }
    private var accentBlue: Color { Color(red: 0.20, green: 0.36, blue: 0.86) }
    private var contentScrollMaxHeight: CGFloat { 300 }
    private var displayedPronunciations: [PronunciationVariant] {
        guard let result = appState.latestResult else { return [] }
        if appState.settingsStore.settings.useIPA {
            return result.pronunciations.filter { !$0.ipa.isEmpty && $0.ipa != "暂无音标" }
        }
        return result.commonPronunciations.filter { ($0.displayText?.isEmpty == false) }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            cardSurface,
                            cardSurfaceAccent
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.52, green: 0.69, blue: 1.0).opacity(isDarkMode ? 0.12 : 0.22),
                                    .clear
                                ],
                                center: .bottomLeading,
                                startRadius: 20,
                                endRadius: 220
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous)
                        .stroke(cardBorder, lineWidth: 0.9)
                )

            VStack(alignment: .leading, spacing: 18) {
                if !appState.hasAccessibilityPermission {
                    permissionBanner
                }

                ScrollView(showsIndicators: true) {
                    Group {
                    if let errorMessage = appState.errorMessage {
                        errorCard(message: errorMessage)
                    } else if let result = appState.latestResult {
                        resultCard(result)
                    } else {
                        emptyState
                    }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: contentScrollMaxHeight, alignment: .topLeading)

                HStack(spacing: 10) {
                    Text(appState.settingsStore.settings.shortcut.displayString)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(cardSecondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(cardBadgeBackground)
                        .clipShape(RoundedRectangle(cornerRadius: panelBadgeCornerRadius, style: .continuous))

                    Spacer()

                    actionButton("arrow.clockwise") {
                        Task {
                            await appState.refreshLatestTranslation()
                        }
                    }
                    .disabled(appState.isTranslating)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .frame(width: 500)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.clear)
        .onChange(of: appState.latestResult?.originalText) { _ in
            isOriginalExpanded = false
        }
    }

    private var permissionBanner: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "lock.open.trianglebadge.exclamationmark")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("需要开启辅助功能权限")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(cardPrimaryText)
                Text("没有这个权限时，应用无法读取别的应用里的选中文本。")
                    .font(.system(size: 12))
                    .foregroundStyle(cardSecondaryText)
            }
            Spacer()
            Button("去开启") {
                appState.requestAccessibilityAuthorization()
            }
            .foregroundStyle(cardPrimaryText)
        }
        .padding(12)
        .background(isDarkMode ? Color.orange.opacity(0.12) : Color.orange.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: panelInnerCornerRadius, style: .continuous))
    }

    private func errorCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("翻译失败", systemImage: "exclamationmark.triangle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.red)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(cardPrimaryText)
                .textSelection(.enabled)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardSoftSurface)
        .clipShape(RoundedRectangle(cornerRadius: panelInnerCornerRadius, style: .continuous))
    }

    private func resultCard(_ result: TranslationResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                sourceTitle(result.originalText)

                Spacer()

                Button {
                    appState.toggleFavorite()
                } label: {
                    Image(systemName: appState.isFavorite(result) ? "star.fill" : "star")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(accentBlue)
                }
                .buttonStyle(.plain)
            }

            if !displayedPronunciations.isEmpty {
                HStack(spacing: 16) {
                    ForEach(displayedPronunciations) { pronunciation in
                        pronunciationRow(pronunciation)
                    }
                }
            }

            if shouldShowExpandedOriginal(for: result) && isOriginalExpanded {
                expandedOriginalBlock(result.originalText)
            }

            if result.isEnglishTerm {
                dictionaryMeaningBlock(result.translatedText)
            } else {
                translationBlock(result.translatedText)
            }

            if let notes = result.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 11))
                    .foregroundStyle(cardSecondaryText)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func sourceTitle(_ text: String) -> some View {
        let isCompactTitle = text.count <= 22 && !text.contains("\n")
        if isCompactTitle {
            Text(text)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(cardPrimaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(previewText(text, limit: 56))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(cardPrimaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                if text.count > 56 || text.contains("\n") {
                    Button {
                        isOriginalExpanded.toggle()
                    } label: {
                        HStack(spacing: 5) {
                            Text(isOriginalExpanded ? "收起原文" : "展开原文")
                            Image(systemName: isOriginalExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(cardSecondaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("划词翻译")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(cardPrimaryText)

            Text("在任意应用里先选中文本，再按快捷键即可。")
                .font(.system(size: 14))
                .foregroundStyle(cardSecondaryText)

            Text("支持音标、发音和极简弹层展示。")
                .font(.system(size: 13))
                .foregroundStyle(cardSecondaryText)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func pronunciationRow(_ pronunciation: PronunciationVariant) -> some View {
        HStack(spacing: 6) {
            Text(pronunciation.label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(cardPrimaryText)

            Text(displayPronunciation(pronunciation))
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundStyle(accentBlue)
                .textSelection(.enabled)

            Button {
                appState.playPronunciation(pronunciation)
            } label: {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(accentBlue)
            }
            .buttonStyle(.plain)
        }
    }

    private func actionButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(cardPrimaryText)
                .frame(width: 28, height: 28)
                .background(cardBadgeBackground)
                .clipShape(RoundedRectangle(cornerRadius: panelBadgeCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func translationBlock(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(cardPrimaryText)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func expandedOriginalBlock(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("完整原文")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(cardSecondaryText)

            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(cardPrimaryText)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(cardSoftSurface)
        .clipShape(RoundedRectangle(cornerRadius: panelInnerCornerRadius, style: .continuous))
    }

    private func dictionaryMeaningBlock(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parsedMeaningLines(text), id: \.self) { line in
                if let dotIndex = line.firstIndex(of: "."), dotIndex < line.index(line.startIndex, offsetBy: min(6, line.count)) {
                    let pos = String(line[..<line.index(after: dotIndex)])
                    let content = String(line[line.index(after: dotIndex)...]).trimmingCharacters(in: .whitespaces)
                    HStack(alignment: .top, spacing: 8) {
                        Text(pos)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(cardMutedText)
                            .frame(width: 26, alignment: .leading)
                        Text(content)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(cardPrimaryText)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text(line)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(cardPrimaryText)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func parsedMeaningLines(_ text: String) -> [String] {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func previewText(_ text: String, limit: Int) -> String {
        let flattened = text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard flattened.count > limit else { return flattened }
        let index = flattened.index(flattened.startIndex, offsetBy: limit)
        return String(flattened[..<index]) + "..."
    }

    private func shouldShowExpandedOriginal(for result: TranslationResult) -> Bool {
        result.originalText.count > 56 || result.originalText.contains("\n")
    }

    private func displayPronunciation(_ pronunciation: PronunciationVariant) -> String {
        if appState.settingsStore.settings.useIPA {
            return squareBracketedIPA(pronunciation.ipa)
        }
        return pronunciation.displayText ?? ""
    }

    private func squareBracketedIPA(_ value: String) -> String {
        var value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value.replacingOccurrences(of: "/", with: "")
        if !value.hasPrefix("[") {
            value = "[\(value)"
        }
        if !value.hasSuffix("]") {
            value += "]"
        }
        return value
    }
}

struct FavoritesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var appState: AppState

    private var isDarkMode: Bool { colorScheme == .dark }
    private var pageBackground: Color { isDarkMode ? Color(red: 0.15, green: 0.16, blue: 0.17) : Color(nsColor: .windowBackgroundColor) }
    private var cardBackground: Color { isDarkMode ? Color.white.opacity(0.06) : Color.white }
    private var cardBorder: Color { isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06) }
    private var cardPrimaryText: Color { isDarkMode ? .white : Color(red: 0.10, green: 0.10, blue: 0.11) }
    private var cardSecondaryText: Color { isDarkMode ? Color(red: 0.70, green: 0.72, blue: 0.76) : Color(red: 0.45, green: 0.47, blue: 0.51) }
    private var accentBlue: Color { Color(red: 0.20, green: 0.36, blue: 0.86) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("收藏")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(cardPrimaryText)

            if appState.favorites.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("还没有收藏的词条")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(cardPrimaryText)
                    Text("在翻译弹层右上角点星标，就会出现在这里。")
                        .font(.system(size: 13))
                        .foregroundStyle(cardSecondaryText)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(appState.favorites) { item in
                            favoriteCard(item)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(minWidth: 460, minHeight: 560, alignment: .topLeading)
        .background(pageBackground)
    }

    private func favoriteCard(_ item: FavoriteItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 7) {
                Text(previewText(item.originalText, limit: 48))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(cardPrimaryText)
                    .lineLimit(1)
                Text(previewText(item.translatedText, limit: 78))
                    .font(.system(size: 13))
                    .foregroundStyle(cardSecondaryText)
                    .lineLimit(2)
                if !displayedPronunciations(for: item).isEmpty {
                    HStack(spacing: 14) {
                        ForEach(displayedPronunciations(for: item)) { pronunciation in
                            HStack(spacing: 5) {
                                Text(pronunciation.label)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(cardSecondaryText)
                                Text(displayPronunciation(pronunciation))
                                    .font(.system(size: 12, weight: .medium, design: .serif))
                                    .foregroundStyle(accentBlue)
                                Button {
                                    appState.playFavoritePronunciation(item, pronunciation: pronunciation)
                                } label: {
                                    Image(systemName: "speaker.wave.2")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(accentBlue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 8)

            HStack(spacing: 12) {
                Button("查看") {
                    appState.showFavorite(item)
                }
                .buttonStyle(.plain)
                .foregroundStyle(cardSecondaryText)

                Button {
                    appState.removeFavorite(item)
                } label: {
                    Image(systemName: "star.slash")
                }
                .buttonStyle(.plain)
                .foregroundStyle(cardSecondaryText)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: panelInnerCornerRadius, style: .continuous)
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: panelInnerCornerRadius, style: .continuous)
                .stroke(cardBorder, lineWidth: 0.8)
        )
    }

    private func displayPronunciation(_ pronunciation: PronunciationVariant) -> String {
        if appState.settingsStore.settings.useIPA {
            return squareBracketedIPA(pronunciation.ipa)
        }
        return pronunciation.displayText ?? ""
    }

    private func previewText(_ text: String, limit: Int) -> String {
        let flattened = text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard flattened.count > limit else { return flattened }
        let index = flattened.index(flattened.startIndex, offsetBy: limit)
        return String(flattened[..<index]) + "..."
    }

    private func displayedPronunciations(for item: FavoriteItem) -> [PronunciationVariant] {
        if appState.settingsStore.settings.useIPA {
            return item.pronunciations.filter { !$0.ipa.isEmpty && $0.ipa != "暂无音标" }
        }
        return item.commonPronunciations.filter { ($0.displayText?.isEmpty == false) }
    }

    private func squareBracketedIPA(_ value: String) -> String {
        var value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value.replacingOccurrences(of: "/", with: "")
        if !value.hasPrefix("[") {
            value = "[\(value)"
        }
        if !value.hasSuffix("]") {
            value += "]"
        }
        return value
    }
}

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var settingsStore: SettingsStore
    let onShortcutChanged: () -> Void
    private let permissionRefreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text("LLM 配置")
                        .font(.system(size: 14, weight: .semibold))
                    TextField("API Endpoint", text: binding(\.apiEndpoint))
                    SecureField("API Key", text: binding(\.apiKey))
                    TextField("Model", text: binding(\.model))
                    TextField("Target Language", text: binding(\.targetLanguage))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .groupBoxStyle(SettingsCardGroupBoxStyle())

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text("快捷键")
                        .font(.system(size: 14, weight: .semibold))
                    ShortcutRecorder(shortcut: binding(\.shortcut)) { isRecording in
                        if isRecording {
                            HotKeyManager.shared.unregister()
                        } else {
                            onShortcutChanged()
                        }
                    }
                    .frame(height: 32)
                    Text("点击输入框后，直接按新的组合键。至少包含一个修饰键。")
                        .font(.system(size: 12))
                        .foregroundStyle(formSecondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .groupBoxStyle(SettingsCardGroupBoxStyle())

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text("音标显示")
                        .font(.system(size: 14, weight: .semibold))
                    Toggle(isOn: binding(\.useIPA)) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("使用 IPA 音标")
                                .font(.system(size: 13, weight: .medium))
                            Text("开启后只显示词典查到的 IPA；关闭后显示更常见的英式/美式学习音标。")
                                .font(.system(size: 12))
                                .foregroundStyle(formSecondaryText)
                        }
                    }
                    .toggleStyle(.switch)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .groupBoxStyle(SettingsCardGroupBoxStyle())

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text("权限状态")
                        .font(.system(size: 14, weight: .semibold))

                    HStack {
                        Circle()
                            .fill(appState.hasAccessibilityPermission ? Color.green : Color.orange)
                            .frame(width: 10, height: 10)
                        Text(appState.hasAccessibilityPermission ? "辅助功能权限已开启" : "辅助功能权限未开启")
                            .font(.system(size: 13, weight: .medium))
                    }

                    Text("应用需要读取当前其他应用中的选中文本，所以必须获得 macOS 辅助功能权限。")
                        .font(.system(size: 12))
                        .foregroundStyle(formSecondaryText)

                    HStack {
                        Button("去授权") {
                            appState.requestAccessibilityAuthorization()
                        }
                        .buttonStyle(SettingsActionButtonStyle())

                        Button("刷新状态") {
                            appState.refreshPermissionStatus()
                        }
                        .buttonStyle(SettingsActionButtonStyle())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .groupBoxStyle(SettingsCardGroupBoxStyle())

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Text("使用说明")
                        .font(.system(size: 14, weight: .semibold))
                    Text("本应用面向英文阅读与学习场景。开启 IPA 时，只显示词典查到的标准音标；关闭 IPA 时，会显示更常见、更适合学习的英式和美式音标写法。")
                        .font(.system(size: 12))
                        .foregroundStyle(formSecondaryText)
                    Text("任何建议可邮件给 sengozhao@icloud.com")
                        .font(.system(size: 12))
                        .foregroundStyle(formSecondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .groupBoxStyle(SettingsCardGroupBoxStyle())

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(width: 640, height: 700, alignment: .topLeading)
        .onAppear {
            appState.refreshPermissionStatus()
        }
        .onChange(of: settingsStore.settings.shortcut) { _ in
            onShortcutChanged()
        }
        .onReceive(permissionRefreshTimer) { _ in
            appState.refreshPermissionStatus()
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { settingsStore.settings[keyPath: keyPath] },
            set: { settingsStore.settings[keyPath: keyPath] = $0 }
        )
    }
}

private struct SettingsCardGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            configuration.content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: settingsCardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: settingsCardCornerRadius, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.8)
        )
    }
}

private struct SettingsActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: settingsButtonCornerRadius, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: settingsButtonCornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(configuration.isPressed ? 0.12 : 0.08), lineWidth: 0.8)
            )
    }
}
