import Foundation

public class OpenRouterManager {
    private let apiKey: String
    private let baseURL = "https://openrouter.ai/api/v1"
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func sendMessage(_ message: String, imagePaths: [String] = [], base64ImgURLs: [String] = []) async throws -> String {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        var content: [[String: Any]] = [["type": "text", "text": message]]
        
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
        
        for img_url in base64ImgURLs {
            content.append([
                "type": "image_url",
                "image_url": ["url": img_url]
            ])
        }
        
        let requestBody: [String: Any] = [
            "model": "anthropic/claude-haiku-4.5",
            "messages": [["role": "user", "content": content]],
            "max_tokens": 1024
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        return response.choices.first?.message.content ?? "No response"
    }
    
    private func getMimeType(for extension: String) -> String? {
        switch `extension`.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        default: return nil
        }
    }
}

struct OpenRouterResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
}
