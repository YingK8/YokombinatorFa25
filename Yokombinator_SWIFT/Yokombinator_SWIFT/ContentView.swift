import SwiftUI

struct ContentView: View {
    @State private var overlayText: String = "Waiting for data..."
    @State private var happiness: Double = 50.0

    var body: some View {
        ZStack {
            // Camera feed
            CameraView(processedText: $overlayText, happiness: $happiness)
                .ignoresSafeArea()

            VStack {
                Spacer()

                HStack(alignment: .center, spacing: 12) {
                    // Text overlay (pink box)
                    Text(overlayText)
                        .font(.headline)
                        .padding()
                        .background(Color.pink.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .multilineTextAlignment(.leading)

                    // Happiness sprite
                    Image(spriteName(for: happiness))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .shadow(radius: 5)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: happiness)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }

    /// Choose the sprite based on happiness range.
    func spriteName(for value: Double) -> String {
        switch value {
        case 0..<40:
            return "squirrel_sad"      // 🐿️ sad squirrel
        case 40..<70:
            return "squirrel_neutral"  // 😐 neutral squirrel
        default:
            return "squirrel_happy"    // 😄 happy squirrel
        }
    }
}
