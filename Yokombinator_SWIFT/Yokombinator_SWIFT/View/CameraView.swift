import SwiftUI
import AVFoundation

// This struct is the bridge between SwiftUI and the UIKit CameraViewController
struct CameraView: UIViewControllerRepresentable {
    
    // 1. A binding to the @State variable in ContentView.
    //    When we update this, the text in ContentView changes.
    @Binding var processedText: String

    // 2. This creates the Coordinator, which will act as the ImageProcessor
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // 3. This creates the initial CameraViewController
    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController()
        
        // 4. Set the coordinator as the image processor.
        //    Now, when CameraViewController gets a screenshot,
        //    it will call coordinator.process(base64String: ...)
        viewController.imageProcessor = context.coordinator
        
        return viewController
    }

    // 4. Required function, but we don't need to update the controller
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Not needed for this use case
    }

    // 5. The Coordinator class acts as the delegate/processor
    class Coordinator: NSObject, ImageProcessor {
        var parent: CameraView
        
        // --- ADDED ---
        // 1. Add an instance of the OpenRouterManager
        private let openRouterManager: OpenRouterManager
        
        // 2. Add a default prompt for the model
        //    (I've removed the formatting instructions from the prompt itself,
        //    as it's better to ask the model for clean text and then we parse it)
        private let processingPrompt = """
        You are a squirrel. Give a short, direct, one-sentence (less than 15 words) reaction to this image.
        On a new line, give a "squirrel happiness percentage" as a number (e.g., 85%).
        """

        init(_ parent: CameraView) {
            self.parent = parent
            
            // --- ADDED ---
            // 3. Initialize the manager.
            // --- IMPORTANT ---
            // Replace with your actual API key.
            // For a real app, you should load this from a secure plist or environment variable.
            let apiKey = "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"
            
            if apiKey == "YOUR_OPENROUTER_API_KEY_HERE" {
                print("--- WARNING: OpenRouterManager API Key is not set. Please add it in CameraView.swift ---")
            }
            self.openRouterManager = OpenRouterManager(apiKey: apiKey)
        }

        // 6. This is the function required by our ImageProcessor protocol!
        //    It's called by CameraViewController on the main thread.
        func process(base64String: String) {
            
            // 7. Update the UI to show we are processing
            DispatchQueue.main.async {
                self.parent.processedText = "Processing image..."
            }
            
            // 8. Create an async Task to perform the network request
            //    without blocking the main thread.
            Task {
                var newText: String
                do {
                    // 9. Call the manager with the prompt and the new base64 image
                    let response = try await openRouterManager.sendMessage(
                        processingPrompt,
                        imagePaths: [],
                        base64ImgURLs: [base64String]
                    )
                    
                    // --- DEBUGGED ---
                    // 10. Parse the raw response into a clean string
                    newText = self.parseSquirrelResponse(response)
                    
                } catch {
                    // 11. Handle any errors
                    print("Failed to send message to OpenRouter: \(error)")
                    newText = "Error: \(error.localizedDescription)"
                }
                
                // 12. Update the UI on the main thread with the final result
                DispatchQueue.main.async {
                    self.parent.processedText = newText
                }
            }
        }
        
        /**
         Parses the AI's response to find the reaction and happiness percentage.
         */
        private func parseSquirrelResponse(_ response: String) -> String {
            // Split the response by new lines
            let lines = response.split(whereSeparator: \.isNewline)
            
            // Simple parsing: assume first non-empty line is the reaction
            // and the last non-empty line contains the percentage.
            
            let reaction = lines.first(where: { !$0.isEmpty })?.trimmingCharacters(in: .whitespaces)
            let happinessLine = lines.last(where: { !$0.isEmpty })?.trimmingCharacters(in: .whitespaces)
            
            // Extract the percentage (e.g., "85%", "Happiness: 90%")
            let happiness = happinessLine?
                .components(separatedBy: CharacterSet.decimalDigits.inverted)
                .joined()
            
            // Build the final string
            var result = ""
            if let reaction = reaction, !reaction.isEmpty {
                result += "Squirrel: \"\(reaction)\""
            } else {
                // Fallback if parsing fails
                return response // Return the raw response
            }
            
            if let happiness = happiness, !happiness.isEmpty {
                result += " (Happiness: \(happiness)%)"
            }
            
            return result
        }
    }
}

