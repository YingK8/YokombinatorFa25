import SwiftUI

struct ContentView: View {
    var body: some View {
        CameraView()
            // Makes the camera view fill the entire screen,
            // ignoring the safe areas (like the notch and home bar).
            .ignoresSafeArea()
    }
}
