//
//  CameraView.swift
//  Yokombinator_SWIFT
//
//  Created by Kakala on 25/10/2025.
//


import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraController = CameraController()
    @State private var capturedImage: UIImage?
    @State private var isShowingPreview = false
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreviewView(cameraController: cameraController)
                .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                headerView
                Spacer()
                controlsView
            }
            
            // Error/Status Messages
            if cameraController.isLoading {
                loadingView
            }
            
            if let error = cameraController.error {
                errorView(error: error)
            }
        }
        .onAppear {
            cameraController.startSession()
        }
        .onDisappear {
            cameraController.stopSession()
        }
        .sheet(isPresented: $isShowingPreview) {
            if let image = capturedImage {
                ImagePreviewView(image: image, isPresented: $isShowingPreview)
            }
        }
    }
    
    private var headerView: some View {
        VStack {
            Text("Camera Feed")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Back Camera Priority")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            if let cameraType = cameraController.activeCameraType {
                Text(cameraType)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(12)
            }
        }
        .padding(.top, 60)
    }
    
    private var controlsView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 30) {
                // Switch Camera Button
                Button(action: {
                    cameraController.switchCamera()
                }) {
                    Image(systemName: "camera.rotate")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                
                // Capture Button
                Button(action: {
                    cameraController.capturePhoto { image in
                        capturedImage = image
                        isShowingPreview = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 70, height: 70)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                    }
                }
                
                // Flash Button
                Button(action: {
                    cameraController.toggleFlash()
                }) {
                    Image(systemName: cameraController.flashMode == .on ? "bolt.fill" : "bolt.slash")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
            }
            
            // Camera Info
            VStack(spacing: 8) {
                Text("Back camera prioritized for mobile devices")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Label("Live", systemImage: "circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    
                    Label("Active", systemImage: "camera.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.bottom, 30)
        }
    }
    
    private var loadingView: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Initializing Camera...")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
    }
    
    private func errorView(error: String) -> some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "camera.metering.unknown")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                Text("Camera Error")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(error)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Try Again") {
                    cameraController.startSession()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding()
        }
    }
}

// MARK: - Camera Preview UIViewRepresentable
struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraController: CameraController
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        cameraController.previewLayer.frame = view.frame
        view.layer.addSublayer(cameraController.previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        cameraController.previewLayer.frame = uiView.frame
    }
}

// MARK: - Image Preview View
struct ImagePreviewView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Button("Save to Photos") {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Photo Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}






final class MockCameraController: CameraController {
    override init() {
        super.init()
        self.isLoading = false
        self.error = nil
        self.activeCameraType = "Back Camera"
    }

    override func startSession() {
        // No-op for previews
    }

    override func stopSession() {
        // No-op
    }

    override func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        completion(UIImage(systemName: "photo"))
    }

    override func switchCamera() {
        activeCameraType = (activeCameraType == "Back Camera") ? "Front Camera" : "Back Camera"
    }
}


#Preview("Normal State") {
    CameraView()
}

#Preview("Loading State") {
    CameraView()
        .environmentObject(MockCameraController())
        .onAppear {
            let mock = MockCameraController()
            mock.isLoading = true
        }
}

#Preview("Error State") {
    var mock = MockCameraController()
    mock.error = "Unable to access camera."
    return CameraView()
        .environmentObject(mock)
}
