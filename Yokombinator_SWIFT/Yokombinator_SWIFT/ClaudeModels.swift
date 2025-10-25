//
//  ClaudeMessage.swift
//  Yokombinator_SWIFT
//
//  Created by Kakala on 25/10/2025.
//


import Foundation

// MARK: - Request Models
struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
    let temperature: Double?
    let stream: Bool?
    
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
        case temperature
        case stream
    }
    
    init(model: String = "claude-3-sonnet-20240229", 
         maxTokens: Int = 1024,
         messages: [ClaudeMessage],
         temperature: Double? = 0.7,
         stream: Bool = false) {
        self.model = model
        self.maxTokens = maxTokens
        self.messages = messages
        self.temperature = temperature
        self.stream = stream
    }
}

// MARK: - Response Models
struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [Content]
    let model: String
    let stopReason: String?
    let stopSequence: String?
    let usage: Usage
    
    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
        case usage
    }
}

struct Content: Codable {
    let type: String
    let text: String
}

struct Usage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// MARK: - Error Models
struct ClaudeError: Codable, Error {
    let type: String
    let message: String
}

struct ClaudeAPIError: Codable, Error {
    let error: ClaudeError
}
