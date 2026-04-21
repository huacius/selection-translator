import AppKit
import Carbon
import Foundation

struct PronunciationVariant: Codable, Equatable, Identifiable {
    var label: String
    var ipa: String
    var displayText: String?
    var audioURLString: String?

    var id: String {
        "\(label)|\(ipa)|\(displayText ?? "")|\(audioURLString ?? "")"
    }

    var audioURL: URL? {
        guard let audioURLString, !audioURLString.isEmpty else { return nil }
        return URL(string: audioURLString)
    }
}

struct Shortcut: Codable, Equatable {
    var key: String
    var command: Bool
    var option: Bool
    var control: Bool
    var shift: Bool

    static let `default` = Shortcut(key: "e", command: true, option: false, control: false, shift: false)

    var displayString: String {
        var parts: [String] = []
        if command { parts.append("Command") }
        if option { parts.append("Option") }
        if control { parts.append("Control") }
        if shift { parts.append("Shift") }
        parts.append(key.uppercased())
        return parts.joined(separator: "+")
    }

    var carbonModifiers: UInt32 {
        var flags: UInt32 = 0
        if command { flags |= UInt32(cmdKey) }
        if option { flags |= UInt32(optionKey) }
        if control { flags |= UInt32(controlKey) }
        if shift { flags |= UInt32(shiftKey) }
        return flags
    }

    var carbonKeyCode: UInt32? {
        Self.keyCodeMap[key.lowercased()]
    }

    var isValid: Bool {
        carbonKeyCode != nil && (command || option || control || shift)
    }

    private static let keyCodeMap: [String: UInt32] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9,
        "b": 11, "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17, "1": 18, "2": 19,
        "3": 20, "4": 21, "6": 22, "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28,
        "0": 29, "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35, "l": 37, "j": 38,
        "'": 39, "k": 40, ";": 41, "\\": 42, ",": 43, "/": 44, "n": 45, "m": 46, ".": 47
    ]

    private static let reverseKeyCodeMap: [UInt16: String] = {
        Dictionary(uniqueKeysWithValues: keyCodeMap.map { (key, value) in (UInt16(value), key) })
    }()

    static func from(event: NSEvent) -> Shortcut? {
        guard let key = Self.reverseKeyCodeMap[event.keyCode] else {
            return nil
        }

        let flags = event.modifierFlags.intersection(NSEvent.ModifierFlags.deviceIndependentFlagsMask)
        let shortcut = Shortcut(
            key: key,
            command: flags.contains(NSEvent.ModifierFlags.command),
            option: flags.contains(NSEvent.ModifierFlags.option),
            control: flags.contains(NSEvent.ModifierFlags.control),
            shift: flags.contains(NSEvent.ModifierFlags.shift)
        )
        return shortcut.isValid ? shortcut : nil
    }
}

struct AppSettings: Codable, Equatable {
    var apiEndpoint: String
    var apiKey: String
    var model: String
    var targetLanguage: String
    var shortcut: Shortcut
    var useIPA: Bool

    static let `default` = AppSettings(
        apiEndpoint: "https://api.openai.com/v1/chat/completions",
        apiKey: "",
        model: "gpt-4.1-mini",
        targetLanguage: "简体中文",
        shortcut: .default,
        useIPA: false
    )
}

struct TranslationResponse: Codable {
    var sourceLanguage: String
    var translatedText: String
    var originalText: String
    var notes: String?
    var commonPronunciationUK: String?
    var commonPronunciationUS: String?
}

struct DictionaryEntry {
    var pronunciations: [PronunciationVariant]
}

struct TranslationResult: Codable, Equatable {
    var originalText: String
    var translatedText: String
    var sourceLanguage: String
    var targetLanguage: String
    var pronunciations: [PronunciationVariant]
    var commonPronunciations: [PronunciationVariant]
    var notes: String?

    var isEnglishTerm: Bool {
        sourceLanguage.lowercased().contains("english")
            && originalText.range(of: #"^[A-Za-z][A-Za-z\s'\-]*$"#, options: .regularExpression) != nil
    }
}

struct FavoriteItem: Codable, Equatable, Identifiable {
    var originalText: String
    var translatedText: String
    var sourceLanguage: String
    var targetLanguage: String
    var pronunciations: [PronunciationVariant]
    var commonPronunciations: [PronunciationVariant]
    var notes: String?
    var createdAt: Date

    var id: String {
        originalText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(result: TranslationResult, createdAt: Date = .now) {
        self.originalText = result.originalText
        self.translatedText = result.translatedText
        self.sourceLanguage = result.sourceLanguage
        self.targetLanguage = result.targetLanguage
        self.pronunciations = result.pronunciations
        self.commonPronunciations = result.commonPronunciations
        self.notes = result.notes
        self.createdAt = createdAt
    }

    var asTranslationResult: TranslationResult {
        TranslationResult(
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            pronunciations: pronunciations,
            commonPronunciations: commonPronunciations,
            notes: notes
        )
    }
}
