//
//  AVSessionFactory.swift
//  Chat
//
//  Created by Ben Whittle on 1/24/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import AVFoundation

// Factory to churn out new, properly configured AV capture sessions.
class AVSessionFactory {
    
    // Create and configure a new AV capture session.
    func createSession(
        outputDelegate: AVCaptureAudioDataOutputSampleBufferDelegate & AVCaptureVideoDataOutputSampleBufferDelegate,
        outputThread: DispatchQueue) -> AVCaptureSession {
        
        // Create new capture session.
        let session = AVCaptureSession()
        
        // Begin configuration of session.
        session.beginConfiguration()
        
        // Add audio input.
        addInput(ofType: .audio, to: session)
        
        // Add video input.
        addInput(ofType: .video, to: session)
        
        // Add audio output.
        addAudioOutput(to: session, delegate: outputDelegate, thread: outputThread)
        
        // Add video output.
        addVideoOutput(to: session, delegate: outputDelegate, thread: outputThread)

        // End configuration of session.
        session.commitConfiguration()
        
        return session
    }
    
    // Add a device input to an AV capture session.
    private func addInput(ofType type: AVMediaType, to session: AVCaptureSession) {
        // Get the default device for this media type.
        guard let device = AVCaptureDevice.default(for: type) else {
            logger.error("No default AV capture device found for type: \(type).")
            return
        }

        // Try to create an input from the found device.
        let input = try? AVCaptureDeviceInput(device: device)
        
        // Ensure device input can be added to the provided capture session.
        guard let deviceInput = input, session.canAddInput(deviceInput) else {
            logger.error("Device input can't be added to AV capture session: \(type).")
            return
        }
        
        // Add the input to the AV capture session.
        session.addInput(deviceInput)
    }
    
    // Add a new audio output to an AV capture session.
    private func addAudioOutput(
        to session: AVCaptureSession,
        delegate: AVCaptureAudioDataOutputSampleBufferDelegate,
        thread: DispatchQueue) {

        // Create a new audio data output instance.
        let audioDataOutput = AVCaptureAudioDataOutput()
        
        // Define your audio output
        guard session.canAddOutput(audioDataOutput) else {
            logger.error("Audio data output can't be added to AV capture session.")
            return
        }

        // Configure the delegate and thread to receive the captured audio output on.
        audioDataOutput.setSampleBufferDelegate(delegate, queue: thread)
        
        // Add the output to the AV capture session.
        session.addOutput(audioDataOutput)
    }
    
    // Add a new video output to an AV capture session.
    private func addVideoOutput(
        to session: AVCaptureSession,
        delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        thread: DispatchQueue) {

        // Create a new video data output instance.
        let videoDataOutput = AVCaptureVideoDataOutput()
        
        // Configure video output settings.
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        ]
        
        // Ignore frames that arrive late.
        videoDataOutput.alwaysDiscardsLateVideoFrames = true

        // Define your video output
        guard session.canAddOutput(videoDataOutput) else {
            logger.error("Video data output can't be added to AV capture session.")
            return
        }

        // Configure the delegate and thread to receive the captured video output on.
        videoDataOutput.setSampleBufferDelegate(delegate, queue: thread)
        
        // Add the output to the AV capture session.
        session.addOutput(videoDataOutput)
    }
}
