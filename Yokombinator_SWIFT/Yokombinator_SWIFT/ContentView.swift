//
//  ContentView.swift
//  Yokombinator_SWIFT
//
//  Created by Kakala on 25/10/2025.
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ClaudeCodeGeneratorView()
                .tabItem {
                    Image(systemName: "hammer.fill")
                    Text("Code Gen")
                }
            
            // Your existing camera view
            CameraView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
        }
    }
}
