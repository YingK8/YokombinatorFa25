//
//  wraps.swift
//  Yokombinator_SWIFT_UI
//
//  Created by Kakala on 25/10/2025.
//


//
//  wraps.swift
//  Yokombinator_SWIFT
//
//  Created by Kakala on 25/10/2025.
//


import SwiftUI
import AVFoundation

/// This struct wraps your UIKit CameraViewController so it can be used in a SwiftUI view.
struct CameraView: UIViewControllerRepresentable {
    
    /// Creates the instance of your CameraViewController.
    func makeUIViewController(context: Context) -> CameraViewController {
        return CameraViewController()
    }
    
    /// This function is used to pass data from SwiftUI to your UIKit controller.
    /// We don't need it for this simple example.
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // No update logic needed
    }
}
