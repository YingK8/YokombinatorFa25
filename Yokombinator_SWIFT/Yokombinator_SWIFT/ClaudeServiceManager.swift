//
//  ClaudeServiceManager.swift
//  Yokombinator_SWIFT
//
//  Created by Kakala on 25/10/2025.
//


import Foundation
import ClaudeCodeSDK
import Alamofire

class ClaudeServiceManager: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    @Published var generatedCode: String?
    @Published var isComplete = false
    
    private var client: ClaudeCodeClient?
    
    init() {
        setupClient()
    }
    
    private func setupClient() {
        // Create custom configuration
        let configuration = ClaudeCodeConfiguration(
            command: "claude",
            workingDirectory: getDocumentsDirectory().path,
            environment: [
                "API_KEY": "your-anthropic-api-key-here",
                "ANTHROPIC_API_KEY": "your-anthropic-api-key-here"
            ],
            enableDebugLogging: true,
            additionalPaths: ["/usr/local/bin"],
            commandSuffix: "--"
        )
        
        client = ClaudeCodeClient(configuration: configuration)
    }
    
    func generateCode(from prompt: String) async {
        await MainActor.run {
            isLoading = true
            error = nil
            generatedCode = nil
            isComplete = false
        }
        
        guard let client = client else {
            await MainActor.run {
                error = "Claude client not initialized"
                isLoading = false
            }
            return
        }
        
        // Configure options
        var options = ClaudeCodeOptions()
        options.verbose = true
        options.maxTurns = 5
        options.systemPrompt = "You are a senior iOS engineer specializing in Swift and SwiftUI."
        options.appendSystemPrompt = "After writing code, add comprehensive comments and ensure it follows Swift best practices."
        options.timeout = 300 // 5 minute timeout
        options.model = "claude-3-sonnet-20240229"
        options.permissionMode = .acceptEdits
        options.maxThinkingTokens = 10000
        
        // Tool configuration
        options.allowedTools = ["Read", "Write", "Bash"]
        options.disallowedTools = ["Delete"]
        
        do {
            let result = try await client.runSinglePrompt(
                prompt: prompt,
                outputFormat: .text,
                options: options
            )
            
            await MainActor.run {
                generatedCode = result
                isLoading = false
                isComplete = true
            }
            
        } catch {
            await MainActor.run {
                self.error = "Error: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func generateSwiftUIComponent(description: String) async {
        let prompt = """
        Create a SwiftUI component with the following description: \(description)
        
        Requirements:
        - Use SwiftUI and modern iOS development practices
        - Include proper state management using @State, @StateObject, or @ObservedObject
        - Add comprehensive comments
        - Make it responsive and accessible
        - Follow Swift naming conventions
        - Include previews if applicable
        
        Return only the Swift code without any markdown formatting or additional text.
        """
        
        await generateCode(from: prompt)
    }
    
    func debugSwiftCode(code: String, issue: String) async {
        let prompt = """
        Debug the following Swift code:
        
        \(code)
        
        Issue: \(issue)
        
        Please:
        1. Identify the problem
        2. Provide the fixed code
        3. Explain what was wrong
        4. Suggest best practices to avoid this issue
        
        Return the fixed Swift code with comprehensive comments.
        """
        
        await generateCode(from: prompt)
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}