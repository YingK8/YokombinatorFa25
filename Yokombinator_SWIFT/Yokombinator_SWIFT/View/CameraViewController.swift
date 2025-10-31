//
//  CameraViewController.swift
//  Yokombinator_SWIFT
//
//  Created by Kakala on 25/10/2025.
//


import UIKit
import AVFoundation
import MediaPlayer // ADDED: Import MediaPlayer to hide the system volume HUD

protocol ImageProcessor: AnyObject {
    /**
     Called when a new screenshot has been captured.
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
    
    // 3. A weak reference to an image processor object.
    weak var imageProcessor: ImageProcessor?
    
    // REMOVED: 4. Timer logic properties
    // private var lastCaptureTime: TimeInterval = 0.0
    // private var initialCaptureTime: TimeInterval = 10.0
    // private let screenshotInterval: TimeInterval = 20.0 // seconds
    
    // ADDED: 4. A thread-safe flag to signal a screenshot request
    private let screenshotLock = NSLock()
    private var screenshotRequested: Bool = false

    // ADDED: 5. Volume monitoring properties
    private let audioSession = AVAudioSession.sharedInstance()
    private var volumeObserver: NSKeyValueObservation?
    private var initialVolume: Float?
    private lazy var volumeView: MPVolumeView = {
        // This view hijacks the system volume UI.
        // We make it hidden so the user doesn't see a volume slider.
        let view = MPVolumeView()
        view.frame = .zero
        view.clipsToBounds = true
        return view
    }()
    
    // 5. A CIContext for efficiently converting video frames (CVPixelBuffer) to images
    private let ciContext = CIContext()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // 6. Initialize your manager and encoder
        videoCaptureManager = VideoCaptureManager()
        h264Encoder = H264Encoder()
        
        // 7. Set THIS view controller as the delegate to intercept video frames.
        videoCaptureManager.setVideoOutputDelegate(with: self)
        
        // 8. Setup the preview layer
        setupPreviewLayer()
        
        // ADDED: Add the hidden volume view to the hierarchy
        view.addSubview(volumeView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Make the preview layer fill the screen, even on rotation
        previewLayer?.frame = view.bounds
    }
    
    // 9. Reset the capture time when the view appears
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // CHANGED: Removed timer logic, added volume observer setup
        setupVolumeObserver()
    }
    
    // ADDED: 10. Stop the observer when the view disappears
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopVolumeObserver()
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
    
    // REMOVED: The timer-based 'processScreenshot' function is no longer needed.
    
    // ADDED: This public function flags that a capture is requested.
    /**
     Flags that a screenshot should be captured on the next available video frame.
     This method is thread-safe.
     */
    func requestScreenshot() {
        screenshotLock.lock()
        screenshotRequested = true
        screenshotLock.unlock()
    }
    
    // ADDED: Sets up the KVO listener for volume changes
    private func setupVolumeObserver() {
        do {
            // We must activate the audio session to monitor its volume
            try audioSession.setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
        
        // Store the volume when we start observing
        initialVolume = audioSession.outputVolume
        
        volumeObserver = audioSession.observe(\.outputVolume, options: [.new]) { [weak self] (session, change) in
            guard let self = self, let newVolume = change.newValue else { return }

            // Check if this is the initial, non-user-driven observation call
            if let initialVolume = self.initialVolume {
                self.initialVolume = nil // Clear it so we don't check again
                if newVolume == initialVolume {
                    return // It's the initial call, do nothing
                }
            }
            
            // It's a real volume change, request a screenshot
            print("Volume change detected, requesting screenshot.")
            self.requestScreenshot()
        }
    }
    
    // ADDED: Cleans up the KVO listener
    private func stopVolumeObserver() {
        volumeObserver?.invalidate()
        volumeObserver = nil
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
        
        // Create a CGImage from the CIImage using the CIContext
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to create CGImage from CIImage")
            return nil
        }
        
        // Create a UIImage from the CGImage to easily convert to Data
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
        
        // --- CHANGED: REPLACED TIMER LOGIC WITH FLAG LOGIC ---
        
        // Check if a screenshot has been requested
        screenshotLock.lock()
        let shouldCapture = self.screenshotRequested
        screenshotLock.unlock() // Unlock immediately
        
        if shouldCapture {
            // Reset the flag
            screenshotLock.lock()
            self.screenshotRequested = false
            screenshotLock.unlock()
            
            // Process the capture.
            // This is already on a background queue, so it's fine.
//            print("Thinking...")
            guard let base64String = base64StringFromSampleBuffer(sampleBuffer) else { return }
            
            // Send the base64 string back to the processor on the main thread
            DispatchQueue.main.async {
                self.imageProcessor?.process(base64String: base64String)
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didDrop sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        // Forward dropped frame to encoder if supported
        h264Encoder?.captureOutput(output, didOutput: sampleBuffer, from: connection)
    }
}
