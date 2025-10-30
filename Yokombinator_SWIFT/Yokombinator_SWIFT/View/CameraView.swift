import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var processedText: String
    @Binding var happiness: Double

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController()
        viewController.imageProcessor = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) { }

    class Coordinator: NSObject, ImageProcessor {
        var parent: CameraView
        private let openRouterManager: OpenRouterManager

        private let processingPrompt = """
        You are a squirrel. Give a short, direct, one-sentence (less than 15 words) reaction to this image.
        On a new line, give a "squirrel happiness percentage" as a number (e.g., 85%).
        """

        init(_ parent: CameraView) {
            self.parent = parent
            let apiKey = "YOUR_OPENROUTER_API_KEY_HERE"
            if apiKey == "YOUR_OPENROUTER_API_KEY_HERE" {
                print("--- WARNING: OpenRouterManager API Key is not set. Please add it in CameraView.swift ---")
            }
            self.openRouterManager = OpenRouterManager(apiKey: apiKey)
        }

        func process(base64String: String) {
            DispatchQueue.main.async {
                self.parent.processedText = "Processing image..."
            }
            
            Task {
                var newText: String
                var newHappiness: Double = 0.0
                
                do {
                    let response = try await openRouterManager.sendMessage(
                        processingPrompt,
                        imagePaths: [],
                        base64ImgURLs: [base64String]
                    )
                    
                    (newText, newHappiness) = self.parseSquirrelResponse(response)
                } catch {
                    print("Failed to send message to OpenRouter: \(error)")
                    newText = "Error: \(error.localizedDescription)"
                }
                
                DispatchQueue.main.async {
                    self.parent.processedText = newText
                    self.parent.happiness = newHappiness
                }
            }
        }

        private func parseSquirrelResponse(_ response: String) -> (String, Double) {
            let lines = response.split(whereSeparator: \.isNewline)
            let reaction = lines.first(where: { !$0.isEmpty })?.trimmingCharacters(in: .whitespaces)
            let happinessLine = lines.last(where: { !$0.isEmpty })?.trimmingCharacters(in: .whitespaces)

            let digits = happinessLine?
                .components(separatedBy: CharacterSet.decimalDigits.inverted)
                .joined() ?? "0"
            let happinessValue = Double(digits) ?? 0.0
            
            return (reaction ?? response, min(max(happinessValue, 0), 100))
        }
    }
}
