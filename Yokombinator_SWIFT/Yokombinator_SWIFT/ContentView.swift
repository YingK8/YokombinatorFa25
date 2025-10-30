import SwiftUI

struct ContentView: View {
    @State private var overlayText: String = "Squeek..."
    @State private var happiness: Double = 50.0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Camera feed
            CameraView(processedText: $overlayText, happiness: $happiness)
                .ignoresSafeArea()

            // User icon with rounded corners
            Image("user_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .cornerRadius(25)
                .foregroundColor(.white.opacity(0.9))
//                .shadow(radius: 3)
                .padding()

            VStack {
                Spacer()

                HStack(alignment: .center, spacing: 12) {
                    Text(overlayText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .layoutPriority(1)

                    // Happiness sprite with rounded corners
                    Image(spriteName(for: happiness))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .cornerRadius(30)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: happiness)
                }
                .padding()
                .glassEffect(
                    .regular.tint(
                        Color(red: 255/255, green: 134/255, blue: 141/255).opacity(0.6) ///pink
                        //Color(red: 255/255, green: 127/255, blue: 17/255).opacity(0.3) ///orange
                        //Color(red: 242/255, green: 215/255, blue: 183/255).opacity(0.3) ///beige
                    ),
                    in: RoundedRectangle(cornerRadius: 30)
                )
                .shadow(radius: 5)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }

    /// Choose the sprite based on happiness range.
    func spriteName(for value: Double) -> String {
        switch value {
        case 0..<40:
            return "squirrel_sad"
        case 40..<70:
            return "squirrel_neutral"
        default:
            return "squirrel_happy"
        }
    }
}
