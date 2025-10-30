//
//  CameraViewController.swift
//  Yokombinator_SWIFT
//
//  Created by Kakala on 25/10/2025.
//


import UIKit
import AVFoundation

// CHANGED: 1. Define a protocol for any object that can process an image.
// We make it 'AnyObject' so it can be held as a 'weak' reference.
protocol ImageProcessor: AnyObject {
    /**
     Called when a new screenshot has been captured (approx. every 10 seconds).
     This method will be called on the main thread.
     - Parameters:
       - base64String: The captured screenshot as a base64-encoded JPEG string.
     */
    func process(base64String: String)
}

class CameraViewController: UIViewController {

    // 1. Your existing classes
    private var videoCaptureManager: VideoCaptureManager!
    private var h264Encoder: H264Encoder!
    
    // 2. The new UI layer for displaying the video feed
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    // CHANGED: 3. A weak reference to an image processor object.
    // This replaces the 'delegate'.
    weak var imageProcessor: ImageProcessor?
    
    // ADDED: 4. Timer logic properties for screenshots
    private var lastCaptureTime: TimeInterval = 0.0
    private var initialCaptureTime: TimeInterval = 5.0
    private let screenshotInterval: TimeInterval = 10.0 // seconds
    
    // ADDED: 5. A CIContext for efficiently converting video frames (CVPixelBuffer) to images
    private let ciContext = CIContext()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // 6. Initialize your manager and encoder
        videoCaptureManager = VideoCaptureManager()
        h264Encoder = H264Encoder()
        
        // ADDED: 7. Set THIS view controller as the delegate to intercept video frames.
        // We will then manually forward the frames to the h264Encoder.
        videoCaptureManager.setVideoOutputDelegate(with: self)
        
        // 8. Setup the preview layer
        setupPreviewLayer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Make the preview layer fill the screen, even on rotation
        previewLayer?.frame = view.bounds
    }
    
    // ADDED: 9. Reset the capture time when the view appears
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reset last capture time to ensure a screenshot isn't taken immediately
        // if the view has been off-screen for a while.
        lastCaptureTime = CACurrentMediaTime() + initialCaptureTime
    }

    private func setupPreviewLayer() {
        // 10. Initialize the preview layer with the session from your manager
        previewLayer = AVCaptureVideoPreviewLayer(session: videoCaptureManager.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        // 11. Add the layer to your view's layer hierarchy
        view.layer.addSublayer(previewLayer)
    }
    
    // MARK: - Screenshot Logic
    
    /**
     Checks if it's time to capture a screenshot and processes it.
     This is called from the video output queue, not the main thread.
     */
    private func processScreenshot(from sampleBuffer: CMSampleBuffer) {
        let currentTime = CACurrentMediaTime()
        
        // Check if 10 seconds have passed since the last capture
        if (currentTime - lastCaptureTime) >= screenshotInterval {
            // Update the last capture time
            self.lastCaptureTime = currentTime
            
            // CHANGED: Convert the sample buffer to a base64 string
            guard let base64String = base64StringFromSampleBuffer(sampleBuffer) else { return }
            
            // CHANGED: Send the base64 string back to the processor on the main thread
            DispatchQueue.main.async {
//                print(base64String)
                self.imageProcessor?.process(base64String: base64String)
            }
        }
    }
    
    /**
     Converts a CMSampleBuffer to a base64-encoded JPEG string.
     */
    private func base64StringFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> String? {
        // Get the CVPixelBuffer from the sample buffer
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get image buffer from sample buffer")
            return nil
        }
        
        // Create a CIImage from the pixel buffer
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        print("Created CGImage from CIImage!")
        
        // Create a CGImage from the CIImage using the CIContext
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to create CGImage from CIImage")
            return nil
        }
        
        // Create a UIImage from the CGImage to easily convert to Data
        // This is a convenient intermediate step.
        let uiImage = UIImage(cgImage: cgImage)
        
        // Convert to JPEG data (using 80% compression)
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert UIImage to JPEG data")
            return nil
        }
        
        // Return the base64-encoded string
        return jpegData.base64EncodedString()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        // Forward frame to encoder
        h264Encoder?.captureOutput(output, didOutput: sampleBuffer, from: connection)
        
        // Handle screenshot logic
        processScreenshot(from: sampleBuffer)
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didDrop sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        // Forward dropped frame to encoder if supported
        h264Encoder?.captureOutput(output, didOutput: sampleBuffer, from: connection)
    }
}

