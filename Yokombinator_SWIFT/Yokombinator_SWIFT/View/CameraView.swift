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
        private let processingPrompt = "Describe this image in one short sentence."

        init(_ parent: CameraView) {
            self.parent = parent
            
            // --- ADDED ---
            // 3. Initialize the manager.
            // --- IMPORTANT ---
            // Replace with your actual API key.
            // For a real app, you should load this from a secure plist or environment variable.
            let apiKey = "YOUR_OPENROUTER_API_KEY_HERE"
            
            if apiKey == "YOUR_OPENROUTER_API_KEY_HERE" {
                print("--- WARNING: OpenRouterManager API Key is not set. Please add it in CameraView.swift ---")
            }
            self.openRouterManager = OpenRouterManager(apiKey: apiKey)
        }

        // 6. This is the function required by our ImageProcessor protocol!
        //    It's called by CameraViewController on the main thread.
        func process(base64String: String) {
            
            // --- CHANGED ---
            // We've replaced the simulation with a real network call.
            
            // 7. Update the UI to show we are processing
            DispatchQueue.main.async {
                self.parent.processedText = "Processing image..."
            }
            
            // 8. Create an async Task to perform the network request
            //    without blocking the main thread.
            Task {
                do {
                    // 9. Call the manager with the prompt and the new base64 image
                    let response = try await openRouterManager.sendMessage(
                        processingPrompt,
                        base64Images: [base64String]
                    )
                    
                    // 10. Update the UI on the main thread with the result
                    DispatchQueue.main.async {
                        self.parent.processedText = response
                    }
                } catch {
                    // 11. Handle any errors
                    print("Failed to send message to OpenRouter: \(error)")
                    DispatchQueue.main.async {
                        self.parent.processedText = "Error: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

