//
//  ContentView.swift
//  Yokombinator_SWIFT_UI
//
//  Created by Kakala on 25/10/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // 1. Use your CameraView struct here
        CameraView()
            // 2. Add this modifier to make the camera feed
            //    fill the entire screen, ignoring safe areas
            //    (like the notch and the home bar).
            .ignoresSafeArea()
    }
}
