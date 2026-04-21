import AppKit
import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    static let defaultsKey = "selection_translator_settings"

    @Published var settings: AppSettings {
        didSet {
            persist()
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = .default
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }

}
