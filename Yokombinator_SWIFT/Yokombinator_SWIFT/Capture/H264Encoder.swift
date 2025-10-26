//
//  H264Encoder.swift
//  Yokombinator_SWIFT
//
//  Created by Kakala on 25/10/2025.
//


import AVFoundation
import VideoToolbox

/// Abstract: An Object that receives raw video data and encodes it to H264 Format
class H264Encoder: NSObject {
    
    enum ConfigurationError: Error {
        case cannotCreateSession
        case cannotSetProperties
        case cannotPrepareToEncode
    }
    
    // NEW: A passthrough closure to send the raw buffer to other objects
    var onRawFrame: ((CMSampleBuffer) -> Void)?
    
    // MARK: - dependencies
    
    // Make the session optional, as it will be created on the first frame
    private var _session: VTCompressionSession?
    
    // MARK: - nalu handling
    
    private static let naluStartCode = Data([UInt8](arrayLiteral: 0x00, 0x00, 0x00, 0x01))
    var naluHandling: ((Data) -> Void)?
        
    // MARK: - init
    
    override init() {
        super.init()
    }
    
    // MARK: - Private Setup
    
    /// Creates the VTCompressionSession on the first sample buffer
    private func setupCompressionSession(with sampleBuffer: CMSampleBuffer) throws {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            throw ConfigurationError.cannotCreateSession
        }
        
        // Get the video dimensions from the format description
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        let width = Int(dimensions.width)
        let height = Int(dimensions.height)
        
        print("Setting up H264Encoder with dimensions: \(width)x\(height)")
        
        var compressionSession: VTCompressionSession?
        
        // Create the compression session
        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: Int32(width),
            height: Int32(height),
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: kCFAllocatorDefault,
            outputCallback: compressionOutputCallback,
            refcon: Unmanaged.passUnretained(self).toOpaque(), // Pass a reference to self
            compressionSessionOut: &compressionSession
        )
        
        guard status == noErr, let session = compressionSession else {
            throw ConfigurationError.cannotCreateSession
        }
        
        // Set compression properties
        try setSessionProperties(session)
        
        self._session = session
    }
    
    /// Sets the desired properties on the compression session
    private func setSessionProperties(_ session: VTCompressionSession) throws {
        var status = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        guard status == noErr else { throw ConfigurationError.cannotSetProperties }
        
        status = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Baseline_AutoLevel)
        guard status == noErr else { throw ConfigurationError.cannotSetProperties }
        
        status = VTSessionSetProperty(session, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
        guard status == noErr else { throw ConfigurationError.cannotSetProperties }
        
        // You can also set properties like kVTCompressionPropertyKey_AverageBitRate, etc.
    }
    
    /// Encodes a single frame
    private func encode(buffer: CMSampleBuffer) {
        guard let session = _session,
              let imageBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            return
        }
        
        // Get the presentation timestamp
        let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(buffer)
        
        // Encode the frame
        VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: imageBuffer,
            presentationTimeStamp: presentationTimeStamp,
            duration: .invalid,
            frameProperties: nil,
            sourceFrameRefcon: nil,
            infoFlagsOut: nil
        )
    }
    
    /// The C-style callback function that VideoToolbox calls with encoded data
    private let compressionOutputCallback: VTCompressionOutputCallback = { (
        outputCallbackRefCon: UnsafeMutableRawPointer?,
        sourceFrameRefCon: UnsafeMutableRawPointer?,
        status: OSStatus,
        infoFlags: VTEncodeInfoFlags,
        sampleBuffer: CMSampleBuffer?
    ) in
        
        // 1. Check for errors
        guard status == noErr else {
            print("H264Encoder: Error encoding frame: \(status)")
            return
        }
        
        // 2. Get the H264Encoder instance
        guard let refCon = outputCallbackRefCon else { return }
        let encoder: H264Encoder = Unmanaged.fromOpaque(refCon).takeUnretainedValue()
        
        // 3. Get the encoded sample buffer
        guard let sampleBuffer = sampleBuffer else { return }
        
        // 4. Pass the buffer to the instance method
        encoder.handleEncodedFrame(sampleBuffer)
    }
    
    /// Handles the encoded CMSampleBuffer from the callback
    private func handleEncodedFrame(_ sampleBuffer: CMSampleBuffer) {
        // Check if the frame is a keyframe (contains SPS/PPS)
        let isKeyFrame = !CFDictionaryContainsKey(
            unsafeBitCast(CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true), 0), to: CFDictionary.self),
            unsafeBitCast(kCMSampleAttachmentKey_NotSync, to: UnsafeRawPointer.self)
        )
        
        // 1. Handle Keyframe (SPS/PPS)
        if isKeyFrame {
            guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
                  let spsSet = getParameterSet(from: formatDescription, at: 0),
                  let ppsSet = getParameterSet(from: formatDescription, at: 1) else {
                return
            }
            
            // Send SPS
            naluHandling?(H264Encoder.naluStartCode + spsSet)
            // Send PPS
            naluHandling?(H264Encoder.naluStartCode + ppsSet)
        }
        
        // 2. Handle Encoded Frame Data (NALUs)
        guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            return
        }
        
        var dataLength: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        
        let status = CMBlockBufferGetDataPointer(dataBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &dataLength, dataPointerOut: &dataPointer)
        guard status == noErr, let dataPointer = dataPointer else {
            return
        }
        
        var offset: Int = 0
        // Iterate through the NALUs in the data buffer
        while offset < dataLength - 4 {
            // Read the NALU length (4 bytes)
            var naluLength: UInt32 = 0
            memcpy(&naluLength, dataPointer + offset, 4)
            
            // Convert from Big-Endian to Host-Endian
            naluLength = CFSwapInt32BigToHost(naluLength)
            
            // Create a Data object for this NALU
            let naluData = Data(bytes: dataPointer + offset + 4, count: Int(naluLength))
            
            // Prepend the start code and send it
            naluHandling?(H264Encoder.naluStartCode + naluData)
            
            // Move to the next NALU
            offset += 4 + Int(naluLength)
        }
    }
    
    /// Helper to extract SPS/PPS data from a format description
    private func getParameterSet(from formatDescription: CMFormatDescription, at index: Int) -> Data? {
        var parameterSetPointer: UnsafePointer<UInt8>?
        var parameterSetLength: Int = 0
        var parameterSetCount: Int = 0
        
        let status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
            formatDescription,
            parameterSetIndex: index,
            parameterSetPointerOut: &parameterSetPointer,
            parameterSetSizeOut: &parameterSetLength,
            parameterSetCountOut: &parameterSetCount,
            nalUnitHeaderLengthOut: nil
        )
        
        guard status == noErr, let parameterSetPointer = parameterSetPointer else {
            return nil
        }
        
        return Data(bytes: parameterSetPointer, count: parameterSetLength)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension H264Encoder: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // a point to receive raw video data
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        // NEW: Pass the raw frame to any listener
        // This happens on the videoOutputQueue
        onRawFrame?(sampleBuffer)
        
        // 1. Setup the session if this is the first frame
        if _session == nil {
            do {
                try setupCompressionSession(with: sampleBuffer)
            } catch {
                print("H264Encoder: Failed to setup compression session: \(error)")
                return
            }
        }
        
        // 2. Encode the buffer
        encode(buffer: sampleBuffer)
    }
}
