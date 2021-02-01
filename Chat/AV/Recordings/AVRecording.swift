//
//  AVRecording.swift
//  Chat
//
//  Created by Ben Whittle on 1/30/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import AVFoundation

class AVRecording {
    
    enum AVType {
        case audio
        case video
    }
    
    let fileName = UUID().uuidString
    
    let fileExt = "mp4"
        
    var filePath: URL { Path.tempDir.appendingPathComponent(fileName).appendingPathExtension(fileExt) }
        
    var isConfigured = false

    var size: Int { Path.size(filePath) ?? 0 }
    
    private var videoWriter: AVAssetWriter!
    
    private var videoWriterInput: AVAssetWriterInput!
    
    private var audioWriterInput: AVAssetWriterInput!
    
    private var sessionAtSourceTime: CMTime?
    
    init() {
        buildPipeline()
    }
    
    func configure(sampleBuffer: CMSampleBuffer) {
        guard sessionAtSourceTime == nil else {
            return
        }
        
        sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        videoWriter.startSession(atSourceTime: sessionAtSourceTime!)
        
        isConfigured = true
    }
    
    func append(_ sampleBuffer: CMSampleBuffer, avType: AVType) {
        guard isConfigured else {
            return
        }
        
        switch avType {
        
        // Add new audio buffer.
        case .audio:
            if audioWriterInput.isReadyForMoreMediaData {
                audioWriterInput.append(sampleBuffer)
            }
            
        // Add new video buffer.
        case .video:
            if videoWriterInput.isReadyForMoreMediaData {
                videoWriterInput.append(sampleBuffer)
            }
        }
    }
    
    func finish(remove: Bool, then handler: @escaping () -> Void) {
        videoWriter.finishWriting {
            if remove {
                self.removeFile()
            }
            
            handler()
        }
    }
    
    private func buildPipeline() {
        // Create video writer.
        createVideoWriter()
        
        // Add video writer input.
        addVideoWriterInput()
        
        // Add audio writer input.
        addAudioWriterInput()
        
        // Allow video writer to accept writing.
        videoWriter.startWriting()
    }
    
    private func createVideoWriter() {
        videoWriter = try? AVAssetWriter(url: filePath, fileType: .mp4)
    }
    
    private func addVideoWriterInput() {
        // Create video writer input.
        videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: ChannelAvatarView.Style.VideoPreviewLayer.diameter,
            AVVideoHeightKey: ChannelAvatarView.Style.VideoPreviewLayer.diameter,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 2300000,
            ],
        ])
        
        // Ensure we are exporting data in real time.
        videoWriterInput.expectsMediaDataInRealTime = true

        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }
    }
    
    private func addAudioWriterInput() {
        // Create audio writer input.
        audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 44100,
            AVEncoderBitRateKey: 64000,
        ])
        
        // Ensure we are exporting data in real time.
        audioWriterInput.expectsMediaDataInRealTime = true

        if videoWriter.canAdd(audioWriterInput) {
            videoWriter.add(audioWriterInput)
        }
    }
    
    private func removeFile() {
        try? FileManager.default.removeItem(at: filePath)
    }
}
