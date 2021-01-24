//
//  AVRecorder.swift
//  Chat
//
//  Created by Ben Whittle on 1/23/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import AVFoundation

class AVRecorder {
    
    private let captureSession = AVCaptureSession()
    
    private var audioInput: AVCaptureDeviceInput?
    
    private var videoInput: AVCaptureDeviceInput?
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    func configure() {
        captureSession.beginConfiguration()
        
        configureAudioInput()

        configureVideoInput()
        
        configureVideoPreview()
        
        captureSession.commitConfiguration()
    }
    
    func startRecording() {
        captureSession.startRunning()
    }
    
    func stopRecording() {
        captureSession.stopRunning()
    }
    
    private func configureAudioInput() {
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            return
        }
        
        audioInput = try? AVCaptureDeviceInput(device: audioDevice)

        guard let audioDeviceInput = audioInput, captureSession.canAddInput(audioDeviceInput) else {
            return
        }
        
        captureSession.addInput(audioDeviceInput)
    }
    
    private func configureVideoInput() {
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            return
        }

        videoInput = try? AVCaptureDeviceInput(device: videoDevice)
        
        guard let videoDeviceInput = videoInput, captureSession.canAddInput(videoDeviceInput) else {
            return
        }
        
        captureSession.addInput(videoDeviceInput)
    }
    
    private func configureVideoPreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    }
}

