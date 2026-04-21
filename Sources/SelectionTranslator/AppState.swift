import AppKit
import Foundation

@MainActor
final class AppState: ObservableObject {
    private static let favoritesKey = "selection_translator_favorites"
    private static let accessibilityPromptPendingKey = "selection_translator_accessibility_prompt_pending"

    @Published var latestResult: TranslationResult?
    @Published var isTranslating = false
    @Published var errorMessage: String?
    @Published var hasAccessibilityPermission = PermissionService.isAccessibilityEnabled()
    @Published var menuToastMessage: String?
    @Published var favorites: [FavoriteItem]

    let settingsStore: SettingsStore
    let pronunciationPlayer = PronunciationPlayer()

    private let selectionCaptureService = SelectionCaptureService()
    private let translationService = TranslationService()
    private let dictionaryService = DictionaryService()
    private lazy var panelController = ResultPanelController(appState: self)
    private var menuToastWorkItem: DispatchWorkItem?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        if let data = UserDefaults.standard.data(forKey: Self.favoritesKey),
           let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: data) {
            favorites = decoded
        } else {
            favorites = []
        }
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPermissionStatus()
            }
        }
    }

    func start() {
        refreshPermissionStatus()
        registerHotkey()
    }

    func registerHotkey() {
        guard settingsStore.settings.shortcut.isValid else {
            errorMessage = "当前快捷键无效，请在设置中重新录制。"
            return
        }
        HotKeyManager.shared.register(shortcut: settingsStore.settings.shortcut) { [weak self] in
            Task { @MainActor in
                await self?.translateCurrentSelection()
            }
        }
    }

    func translateCurrentSelection() async {
        guard !isTranslating else { return }
        isTranslating = true
        errorMessage = nil
        refreshPermissionStatus()
        let anchorPoint = NSEvent.mouseLocation

        do {
            let selectedText = try await selectionCaptureService.captureSelectedText()
            async let translation = translationService.translate(selectedText, settings: settingsStore.settings)
            async let dictionary = dictionaryService.lookup(for: selectedText)

            let translationResponse = try await translation
            let dictionaryEntry = await dictionary
            let commonPronunciations = buildCommonPronunciations(from: translationResponse)

            latestResult = TranslationResult(
                originalText: translationResponse.originalText,
                translatedText: translationResponse.translatedText,
                sourceLanguage: translationResponse.sourceLanguage,
                targetLanguage: settingsStore.settings.targetLanguage,
                pronunciations: dictionaryEntry?.pronunciations ?? [],
                commonPronunciations: commonPronunciations,
                notes: translationResponse.notes
            )
            panelController.show(near: anchorPoint)
        } catch {
            errorMessage = error.localizedDescription
            panelController.show(near: anchorPoint)
        }

        isTranslating = false
    }

    func playPronunciation(_ pronunciation: PronunciationVariant? = nil) {
        guard let latestResult else { return }
        let matchedDictionaryAudio = latestResult.pronunciations.first {
            $0.label == pronunciation?.label && $0.audioURL != nil
        }?.audioURL
        pronunciationPlayer.play(
            text: latestResult.originalText,
            audioURL: matchedDictionaryAudio ?? pronunciation?.audioURL ?? latestResult.pronunciations.first?.audioURL
        )
    }

    func playFavoritePronunciation(_ item: FavoriteItem, pronunciation: PronunciationVariant? = nil) {
        let matchedDictionaryAudio = item.pronunciations.first {
            $0.label == pronunciation?.label && $0.audioURL != nil
        }?.audioURL
        pronunciationPlayer.play(
            text: item.originalText,
            audioURL: matchedDictionaryAudio ?? pronunciation?.audioURL ?? item.pronunciations.first?.audioURL
        )
    }

    func refreshPermissionStatus() {
        hasAccessibilityPermission = PermissionService.isAccessibilityEnabled()
    }

    func requestAccessibilityAuthorization() {
        if hasAccessibilityPermission {
            PermissionService.openAccessibilitySettings()
            return
        }

        if Self.shouldShowAccessibilityPrompt {
            _ = PermissionService.promptAccessibilityIfNeeded()
            Self.shouldShowAccessibilityPrompt = false
        } else {
            PermissionService.openAccessibilitySettings()
        }
        schedulePermissionRefreshChecks()
    }

    func closePanel() {
        panelController.hide()
    }

    func isFavorite(_ result: TranslationResult?) -> Bool {
        guard let result else { return false }
        return favorites.contains(where: { $0.id == FavoriteItem(result: result).id })
    }

    func toggleFavorite() {
        guard let latestResult else { return }
        let item = FavoriteItem(result: latestResult)
        if let index = favorites.firstIndex(where: { $0.id == item.id }) {
            favorites.remove(at: index)
            showMenuToast("已取消收藏")
        } else {
            favorites.insert(item, at: 0)
            showMenuToast("已加入收藏")
        }
        persistFavorites()
    }

    func removeFavorite(_ item: FavoriteItem) {
        favorites.removeAll { $0.id == item.id }
        persistFavorites()
        showMenuToast("已移除收藏")
    }

    func showFavorite(_ item: FavoriteItem) {
        latestResult = item.asTranslationResult
        errorMessage = nil
        panelController.show()
    }

    func clearCache() {
        latestResult = nil
        errorMessage = nil
        showMenuToast("已清除临时缓存")
    }

    func resetAccessibilityPermission() {
        do {
            try PermissionService.resetAccessibilityPermission()
            hasAccessibilityPermission = false
            errorMessage = nil
            Self.shouldShowAccessibilityPrompt = true
            showMenuToast("已重置授权，请重新开启辅助功能")
            schedulePermissionRefreshChecks()
        } catch {
            errorMessage = "重置辅助功能授权失败，请手动运行 tccutil reset Accessibility com.sengo.selectiontranslator"
        }
    }

    func showMenuToast(_ message: String) {
        menuToastWorkItem?.cancel()
        menuToastMessage = message
        let workItem = DispatchWorkItem { [weak self] in
            self?.menuToastMessage = nil
        }
        menuToastWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: workItem)
    }

    private func persistFavorites() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: Self.favoritesKey)
    }

    private static var shouldShowAccessibilityPrompt: Bool {
        get {
            if UserDefaults.standard.object(forKey: accessibilityPromptPendingKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: accessibilityPromptPendingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: accessibilityPromptPendingKey)
        }
    }

    private func schedulePermissionRefreshChecks() {
        let delays: [TimeInterval] = [0.2, 0.8, 1.6]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.refreshPermissionStatus()
            }
        }
    }

    private func buildCommonPronunciations(from response: TranslationResponse) -> [PronunciationVariant] {
        var items: [PronunciationVariant] = []

        if let uk = normalizedCommonPronunciation(response.commonPronunciationUK), !uk.isEmpty {
            items.append(
                PronunciationVariant(
                    label: "英",
                    ipa: "",
                    displayText: uk,
                    audioURLString: nil
                )
            )
        }

        if let us = normalizedCommonPronunciation(response.commonPronunciationUS), !us.isEmpty {
            items.append(
                PronunciationVariant(
                    label: "美",
                    ipa: "",
                    displayText: us,
                    audioURLString: nil
                )
            )
        }

        return items
    }

    private func normalizedCommonPronunciation(_ value: String?) -> String? {
        guard var value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
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
