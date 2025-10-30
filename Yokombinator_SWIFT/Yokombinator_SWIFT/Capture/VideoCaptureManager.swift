//
//  VideoCaptureManager.swift
//  Yokombinator_SWIFT
//
//  Created by Kakala on 25/10/2025.
//


import AVFoundation

class VideoCaptureManager {
        
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private enum ConfigurationError: Error {
        case cannotAddInput
        case cannotAddOutput
        case defaultDeviceNotExist
    }
    
    // MARK: - dependencies
    
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    // MARK: - DispatchQueues
    
    private let sessionQueue = DispatchQueue(label: "session.queue")
    private let videoOutputQueue = DispatchQueue(label: "video.output.queue")
    
    private var setupResult: SessionSetupResult = .success

    // MARK: - NEW: Public getter for the session
    
    /// The capture session. Publicly readable for the preview layer.
    var captureSession: AVCaptureSession {
        return session
    }
    
    // MARK: - Init
    
    init() {
        // We use sessionQueue.async to move setup off the main thread.
        sessionQueue.async {
            self.requestCameraAuthorizationIfNeeded()
        }

        sessionQueue.async {
            self.configureSession()
        }
        
        // startSessionIfPossible() is called in configureSession
        // on success, so no need to call it here separately.
    }
    
    func setVideoOutputDelegate(with delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        videoOutput.setSampleBufferDelegate(delegate, queue: videoOutputQueue)
    }

    // MARK: - Session Configuration (Implementations)
    
    private func requestCameraAuthorizationIfNeeded() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Already authorized
            break
        case .notDetermined:
            // Suspend the queue to wait for user response
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
        default:
            // Denied or restricted
            setupResult = .notAuthorized
        }
    }

    /// - Tag: configureSession
    private func configureSession() {
        // Must be on the session queue
        guard setupResult == .success else {
            print("Setup result failed: \(setupResult)")
            return
        }
        
        session.beginConfiguration()
        
        // Configure common session properties
        session.sessionPreset = .high // You can change this preset
        
        do {
            try addVideoDeviceInputToSession()
            try addVideoOutputToSession()
        } catch {
            print("Error configuring session: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration() // Still need to commit config
            return
        }
        
        session.commitConfiguration()
        
        // Start the session *after* configuration
        self.startSessionIfPossible()
    }
    
    /// - Tag: startSession
    private func startSessionIfPossible() {
        // Must be on the session queue
        guard setupResult == .success else {
            print("Cannot start session, setup result: \(setupResult)")
            return
        }
        
        if !session.isRunning {
            session.startRunning()
            print("Capture session started.")
        }
    }

    private func addVideoDeviceInputToSession() throws {
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Find a suitable camera
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                defaultVideoDevice = dualWideCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                defaultVideoDevice = frontCameraDevice
            }
            
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                throw ConfigurationError.defaultDeviceNotExist
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
            } else {
                print("Cannot add video device input to session")
                throw ConfigurationError.cannotAddInput
            }
        } catch {
            print("Error adding video input: \(error)")
            throw error
        }
    }
    
    private func addVideoOutputToSession() throws {
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        } else {
            print("Cannot add video output to session")
            throw ConfigurationError.cannotAddOutput
        }
    }
}
