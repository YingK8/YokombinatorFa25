import AVFoundation
import UIKit
import Combine

class CameraController: NSObject, ObservableObject {
    @Published var isLoading = true
    @Published var error: String?
    @Published var activeCameraType: String?
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    
    var captureSession: AVCaptureSession!
    var videoOutput: AVCaptureVideoDataOutput!
    var photoOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    private var backCamera: AVCaptureDevice?
    private var frontCamera: AVCaptureDevice?
    private var currentCamera: AVCaptureDevice?
    
    override init() {
        super.init()
        setupCaptureSession()
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        setupDevices()
        setupInputs()
        setupOutputs()
        setupPreviewLayer()
    }
    
    private func setupDevices() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTelephotoCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        for device in deviceDiscoverySession.devices {
            switch device.position {
            case .back:
                backCamera = device
            case .front:
                frontCamera = device
            default:
                break
            }
        }
        
        // Prioritize back camera
        currentCamera = backCamera ?? frontCamera
        activeCameraType = currentCamera?.position == .back ? "Back Camera" : "Front Camera"
    }
    
    private func setupInputs() {
        guard let currentCamera = currentCamera else {
            error = "No camera available"
            isLoading = false
            return
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: currentCamera)
            
            if captureSession.canAddInput(cameraInput) {
                captureSession.addInput(cameraInput)
            }
        } catch {
            self.error = "Error setting up camera input: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func setupOutputs() {
        photoOutput = AVCapturePhotoOutput()
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        videoOutput = AVCaptureVideoDataOutput()
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }
    
    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoRotationAngle = 90
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func switchCamera() {
        captureSession.beginConfiguration()
        
        // Remove current input
        if let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput {
            captureSession.removeInput(currentInput)
        }
        
        // Switch camera
        if currentCamera?.position == .back {
            currentCamera = frontCamera
            activeCameraType = "Front Camera"
        } else {
            currentCamera = backCamera
            activeCameraType = "Back Camera"
        }
        
        // Add new input
        if let newCamera = currentCamera {
            do {
                let newInput = try AVCaptureDeviceInput(device: newCamera)
                if captureSession.canAddInput(newInput) {
                    captureSession.addInput(newInput)
                }
            } catch {
                self.error = "Error switching camera: \(error.localizedDescription)"
            }
        }
        
        captureSession.commitConfiguration()
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        
        if let photoOutputConnection = photoOutput.connection(with: .video) {
            photoOutputConnection.videoRotationAngle = 90
        }
        
        // Configure flash
        if currentCamera?.hasFlash == true {
            settings.flashMode = flashMode
        }
        
        photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureDelegate(completion: completion))
    }
    
    func toggleFlash() {
        flashMode = (flashMode == .on) ? .off : .on
    }
}

// MARK: - Photo Capture Delegate
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            completion(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion(nil)
            return
        }
        
        completion(image)
    }
}
