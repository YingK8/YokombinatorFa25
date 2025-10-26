import SwiftUI

struct ContentView: View {
    // 1. A @State variable to hold the text from the processor
    @State private var overlayText: String = "Waiting for data..."

    var body: some View {
        // 2. A ZStack layers views. Views at the bottom appear in the back.
        ZStack {
            // 3. The CameraView is our bridge to the UIKit controller.
            //    We pass the $overlayText binding so it can update our @State.
            CameraView(processedText: $overlayText)
                // Makes the camera view fill the entire screen
                .ignoresSafeArea()
            
            // 4. This Text view is layered on top of the camera
            VStack {
                Spacer() // Pushes the text to the bottom
                Text(overlayText)
                    .font(.headline)
                    .padding()
                    .background(Color.black.opacity(0.6)) // Semi-transparent background
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 30) // Add padding from the home bar
            }
        }
    }
}
