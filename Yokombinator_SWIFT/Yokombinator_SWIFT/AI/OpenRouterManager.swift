import Foundation

public class OpenRouterManager {
    private let apiKey: String
    private let baseURL = "https://openrouter.ai/api/v1"
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func sendMessage(_ message: String,
                            imagePaths: [String] = [],
                            base64ImgURLs: [String] = []) async throws -> String {
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Build content
        var content: [[String: Any]] = [["type": "text", "text": message]]
        
        // Local images → base64
        for path in imagePaths {
            if let imageData = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let mimeType = getMimeType(for: (path as NSString).pathExtension) {
                let base64 = imageData.base64EncodedString()
                content.append([
                    "type": "image_url",
                    "image_url": ["url": "data:\(mimeType);base64,\(base64)"]
                ])
            }
        }
        
        // Provided base64 strings
        for imgURL in base64ImgURLs {
            content.append([
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(imgURL)"]
            ])
        }
        
        // Build request JSON
        let requestBody: [String: Any] = [
            "model": "anthropic/claude-haiku-4.5",
            "messages": [["role": "user", "content": content]],
            "max_tokens": 2048
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Perform request
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Debug print
        if let raw = String(data: data, encoding: .utf8) {
            print("🔍 Raw OpenRouter response:\n\(raw)")
        }
        
        // Decode flexibly
        if let openAI = try? JSONDecoder().decode(OpenAIResponse.self, from: data) {
            return openAI.choices.first?.message.content ?? "No content"
        } else if let claude = try? JSONDecoder().decode(ClaudeResponse.self, from: data) {
            if let text = claude.output_text {
                return text
            } else if let text = claude.content?.first(where: { $0.text != nil })?.text {
                return text
            } else {
                throw NSError(domain: "OpenRouter", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Claude response missing text content."
                ])
            }
        } else {
            throw NSError(domain: "OpenRouter", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Unknown or malformed response format."
            ])
        }
    }
    
    // Helper
    private func getMimeType(for ext: String) -> String? {
        switch ext.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        default: return nil
        }
    }
}

// MARK: - Response Models

private struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable { let content: String }
        let message: Message
    }
    let choices: [Choice]
}

private struct ClaudeResponse: Codable {
    let id: String?
    let output_text: String?
    let content: [ContentItem]?
    struct ContentItem: Codable {
        let type: String?
        let text: String?
    }
}
