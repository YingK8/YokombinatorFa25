//
//  ClaudeCodeGeneratorView.swift
//  Yokombinator_SWIFT
//
//  Created by Kakala on 25/10/2025.
//


import SwiftUI
import ClaudeCodeSDK

struct ClaudeCodeGeneratorView: View {
    @StateObject private var claudeService = ClaudeServiceManager()
    @StateObject private var apiKeyManager = APIKeyManager()
    @State private var promptText = ""
    @State private var showAPIKeyInput = false
    @State private var apiKeyInput = ""
    @State private var selectedMode = GenerationMode.swiftUIComponent
    
    enum GenerationMode: String, CaseIterable {
        case swiftUIComponent = "SwiftUI Component"
        case debugCode = "Debug Code"
        case customPrompt = "Custom Prompt"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !apiKeyManager.hasAPIKey() {
                    apiKeySetupView
                } else {
                    mainInterface
                }
            }
            .navigationTitle("Claude Code Generator")
            .sheet(isPresented: $showAPIKeyInput) {
                apiKeyInputSheet
            }
        }
    }
    
    private var apiKeySetupView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Claude API Key Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("To use the code generation features, you need to add your Anthropic Claude API key.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Add API Key") {
                showAPIKeyInput = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Spacer()
            
            Text("Your API key is stored securely on your device and never shared.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var mainInterface: some View {
        VStack(spacing: 16) {
            // Mode Selection
            Picker("Generation Mode", selection: $selectedMode) {
                ForEach(GenerationMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Input Area
            Group {
                switch selectedMode {
                case .swiftUIComponent:
                    swiftUIComponentInput
                case .debugCode:
                    debugCodeInput
                case .customPrompt:
                    customPromptInput
                }
            }
            .padding(.horizontal)
            
            // Generate Button
            Button(action: {
                generateCode()
            }) {
                if claudeService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Generate Code")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(claudeService.isLoading || promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal)
            
            // Results
            if let generatedCode = claudeService.generatedCode {
                CodeResultView(code: generatedCode)
            }
            
            if let error = claudeService.error {
                errorView(error: error)
            }
            
            Spacer()
        }
        .padding(.top)
    }
    
    private var swiftUIComponentInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Describe the SwiftUI component you want to create:")
                .font(.headline)
            
            TextEditor(text: $promptText)
                .frame(height: 120)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var debugCodeInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Paste the Swift code to debug and describe the issue:")
                .font(.headline)
            
            TextEditor(text: $promptText)
                .frame(height: 200)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var customPromptInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter your custom prompt:")
                .font(.headline)
            
            TextEditor(text: $promptText)
                .frame(height: 150)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var apiKeyInputSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter Claude API Key")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                SecureField("API Key", text: $apiKeyInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.password)
                
                Text("You can get your API key from the Anthropic console.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Save API Key") {
                    guard !apiKeyInput.isEmpty else { return }
                    if apiKeyManager.saveAPIKey(apiKeyInput) {
                        showAPIKeyInput = false
                        apiKeyInput = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("API Key Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showAPIKeyInput = false
                    }
                }
            }
        }
    }
    
    private func generateCode() {
        guard !promptText.isEmpty else { return }
        
        Task {
            switch selectedMode {
            case .swiftUIComponent:
                await claudeService.generateSwiftUIComponent(description: promptText)
            case .debugCode:
                await claudeService.debugSwiftCode(code: promptText, issue: "Fix any bugs and improve the code")
            case .customPrompt:
                await claudeService.generateCode(from: promptText)
            }
        }
    }
    
    private func errorView(error: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
                .font(.title2)
            
            Text("Error")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - Code Result View
struct CodeResultView: View {
    let code: String
    @State private var showShareSheet = false
    @State private var showCopyConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Generated Code")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = code
                    withAnimation {
                        showCopyConfirmation = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showCopyConfirmation = false
                        }
                    }
                }) {
                    Image(systemName: "doc.on.doc")
                }
                
                Button(action: {
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            
            ScrollView {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(maxHeight: 300)
            
            if showCopyConfirmation {
                Text("Copied to clipboard!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5)
        .padding(.horizontal)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [code])
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}