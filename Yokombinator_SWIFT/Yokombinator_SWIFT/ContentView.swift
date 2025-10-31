import SwiftUI

struct ContentView: View {
    @State private var overlayText: String = "Squeek..."
    @State private var happiness: Double = 0.0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Camera feed background
            CameraView(processedText: $overlayText, happiness: $happiness)
                .ignoresSafeArea()
            
            // Top-left pink glass back button
            Button(action: {
                // Add your back button action here
                print("Back button tapped")
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        ZStack {
                            // Pink tint behind glass
                            Color(red: 255/255, green: 134/255, blue: 141/255)
                                .opacity(0.5)
                            RoundedRectangle(cornerRadius: 25)
                                .fill(.ultraThinMaterial)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
            .padding(.leading, 16)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // Top-right user icon
            Image("user_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .cornerRadius(25)
                .foregroundColor(.white.opacity(0.9))
                .padding()
            
            VStack {
                Spacer() // Push content to bottom
                
                HStack(alignment: .bottom, spacing: 12) {
                    // Pink glass text box
                    Text(overlayText)
                        .font(.custom("VCROSDMono", size: 20, relativeTo: .headline))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 18)
                        .background(
                            ZStack {
                                // Saturated tint behind glass
                                Color(red: 255/255, green: 134/255, blue: 141/255)
                                    .opacity(0.5)
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(.ultraThinMaterial)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    // --- ADD THESE 3 LINES ---
                    // 1. Define the animation timing
                        .animation(.easeInOut(duration: 0.3), value: overlayText)
                    // 2. Set the animation type to a fade
                        .transition(.opacity)
                    // 3. Force SwiftUI to see this as a new view when the text changes
                        .id(overlayText)
                    // --- END OF CHANGES ---
                    
                    // Happiness sprite (fixed dimension)
                    Image(spriteName(for: happiness))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .cornerRadius(35)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: happiness)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }
    /// Choose sprite based on happiness value
    func spriteName(for value: Double) -> String {
        switch value {
        case 0..<40: return "squirrel_sad"
        case 40..<70: return "squirrel_neutral"
        default: return "squirrel_happy"
        }
    }
}
