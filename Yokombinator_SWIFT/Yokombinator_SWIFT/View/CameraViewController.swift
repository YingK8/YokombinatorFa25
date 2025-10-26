//
//  CameraViewController.swift
//  Yokombinator_SWIFT
//
//  Created by Kakala on 25/10/2025.
//


import UIKit
import AVFoundation

class CameraViewController: UIViewController {

    // 1. Your existing classes
    private var videoCaptureManager: VideoCaptureManager!
    private var h264Encoder: H264Encoder!
    
    // 2. The new UI layer for displaying the video feed
    private var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // 3. Initialize your manager and encoder
        videoCaptureManager = VideoCaptureManager()
        h264Encoder = H264Encoder()
        
        // 4. Set the encoder as the delegate to receive video frames
        videoCaptureManager.setVideoOutputDelegate(with: h264Encoder)
        
        // 5. Setup the preview layer
        setupPreviewLayer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Make the preview layer fill the screen, even on rotation
        previewLayer?.frame = view.bounds
    }

    private func setupPreviewLayer() {
        // 6. Initialize the preview layer with the session from your manager
        previewLayer = AVCaptureVideoPreviewLayer(session: videoCaptureManager.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        // 7. Add the layer to your view's layer hierarchy
        view.layer.addSublayer(previewLayer)
    }
}