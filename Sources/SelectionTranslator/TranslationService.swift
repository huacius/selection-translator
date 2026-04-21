import Foundation

struct TranslationService {
    enum TranslationError: LocalizedError {
        case missingConfiguration
        case invalidResponse
        case invalidPayload

        var errorDescription: String? {
            switch self {
            case .missingConfiguration:
                return "请先在设置里填写 LLM 接口地址、API Key 和模型名。"
            case .invalidResponse:
                return "翻译接口返回内容不可识别。"
            case .invalidPayload:
                return "LLM 返回的 JSON 结构不符合预期。"
            }
        }
    }

    private struct ChatRequest: Encodable {
        struct Message: Encodable {
            var role: String
            var content: String
        }

        var model: String
        var temperature: Double
        var messages: [Message]
    }

    private struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                var content: String
            }

            var message: Message
        }

        var choices: [Choice]
    }

    func translate(_ text: String, settings: AppSettings) async throws -> TranslationResponse {
        guard !settings.apiEndpoint.isEmpty, !settings.apiKey.isEmpty, !settings.model.isEmpty else {
            throw TranslationError.missingConfiguration
        }

        let systemPrompt = """
        你是一个极简划词翻译助手，面向英文阅读与学习场景。
        请把用户输入翻译成\(settings.targetLanguage)。
        输出原则：
        1. 如果原文是英文单词或短语，translatedText 请尽量按词典风格输出，每行一个词性义项，格式接近：
           n. 释义1；释义2
           v. 释义1；释义2
           不要编号，不要 markdown。
        2. 如果原文是英文单词，优先给最常见、学习价值高的 2 到 4 行义项，宁可少一点，也不要泛泛堆很多冷僻义项。
        3. 同一个词性不要重复出现；如果有多个近义项，请合并到同一行里，用中文分号分隔。
        4. 如果原文是英文单词或短语，notes 可补一条很短的用法提示、语气差异或常见搭配；没有必要时可留空。
        5. 如果原文是固定短语，translatedText 以自然、好懂的中文释义为主，不必强行拆词性。
        6. 如果原文是英文句子或段落，translatedText 以自然、准确、便于阅读理解为主，不要过度展开。
        7. 如果原文是英文单词或短语，请额外返回更常见、更适合中国用户学习的英式和美式音标写法，不要返回 IPA 符号，不要使用 / /，统一使用方括号格式，例如 [prɒmpt] 这种常见学习展示风格。
        8. 如果原文不是英文单词或短语，commonPronunciationUK 和 commonPronunciationUS 留空即可。
        9. 不要编造词典来源或发音音频信息。
        只返回 JSON，不要输出 markdown，不要补充解释。
        JSON 格式必须严格为：
        {
          "sourceLanguage": "检测到的源语言",
          "originalText": "原文",
          "translatedText": "译文",
          "notes": "可选，只有必要时才写，尽量短",
          "commonPronunciationUK": "可选，英式常见音标写法，例如 [prɒmpt]",
          "commonPronunciationUS": "可选，美式常见音标写法，例如 [prɑːmpt]"
        }
        """

        let requestBody = ChatRequest(
            model: settings.model,
            temperature: 0.2,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: text)
            ]
        )

        guard let url = URL(string: settings.apiEndpoint) else {
            throw TranslationError.missingConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw TranslationError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw TranslationError.invalidResponse
        }

        let jsonData = try extractJSON(from: content)
        guard let parsed = try? JSONDecoder().decode(TranslationResponse.self, from: jsonData) else {
            throw TranslationError.invalidPayload
        }
        return parsed
    }

    private func extractJSON(from content: String) throws -> Data {
        if let raw = content.data(using: .utf8), (try? JSONSerialization.jsonObject(with: raw)) != nil {
            return raw
        }

        guard let start = content.firstIndex(of: "{"), let end = content.lastIndex(of: "}") else {
            throw TranslationError.invalidPayload
        }

        let slice = String(content[start...end])
        guard let data = slice.data(using: .utf8) else {
            throw TranslationError.invalidPayload
        }
        return data
    }
}
