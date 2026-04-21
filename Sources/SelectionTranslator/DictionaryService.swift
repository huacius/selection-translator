import Foundation

struct DictionaryService {
    private struct APIPhonetic: Decodable {
        var text: String?
        var audio: String?
        var sourceUrl: String?
    }

    private struct APIEntry: Decodable {
        var phonetics: [APIPhonetic]
    }

    func lookup(for text: String) async -> DictionaryEntry? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.range(of: #"^[A-Za-z][A-Za-z\s'\-]*$"#, options: .regularExpression) != nil else {
            return nil
        }

        let query = normalized.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? normalized
        guard let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(query)") else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                return nil
            }

            let entries = try JSONDecoder().decode([APIEntry].self, from: data)
            for entry in entries {
                let pronunciations = buildPronunciations(from: entry.phonetics)
                if !pronunciations.isEmpty {
                    return DictionaryEntry(pronunciations: pronunciations)
                }
            }
        } catch {
            return nil
        }

        return nil
    }

    private func buildPronunciations(from phonetics: [APIPhonetic]) -> [PronunciationVariant] {
        var results: [PronunciationVariant] = []

        for phonetic in phonetics {
            let ipa = normalizedIPA(phonetic.text)
            let audioURLString = normalizedAudioURL(phonetic.audio)
            guard ipa != nil || audioURLString != nil else { continue }

            let label = inferredLabel(for: phonetic, existingCount: results.count)
            let variant = PronunciationVariant(
                label: label,
                ipa: ipa ?? "暂无音标",
                displayText: nil,
                audioURLString: audioURLString
            )

            if !results.contains(where: { $0.label == variant.label && $0.ipa == variant.ipa }) {
                results.append(variant)
            }
            if results.count == 2 { break }
        }

        if results.isEmpty, let first = phonetics.first {
            let ipa = normalizedIPA(first.text) ?? "暂无音标"
            let audioURLString = normalizedAudioURL(first.audio)
            if audioURLString != nil || ipa != "暂无音标" {
                results.append(PronunciationVariant(label: "音", ipa: ipa, displayText: nil, audioURLString: audioURLString))
            }
        }

        return results
    }

    private func inferredLabel(for phonetic: APIPhonetic, existingCount: Int) -> String {
        let context = "\(phonetic.sourceUrl ?? "") \(phonetic.text ?? "")".lowercased()
        if context.contains("uk") || context.contains("british") {
            return "英"
        }
        if context.contains("us") || context.contains("american") {
            return "美"
        }
        return existingCount == 0 ? "英" : "美"
    }

    private func normalizedIPA(_ value: String?) -> String? {
        guard var value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        if !value.hasPrefix("/") && !value.hasPrefix("[") {
            value = "/\(value)/"
        }
        return value
    }

    private func normalizedAudioURL(_ value: String?) -> String? {
        guard var value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        if value.hasPrefix("//") {
            value = "https:\(value)"
        }
        return value
    }
}
