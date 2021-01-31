//
//  AVRecorder.swift
//  Chat
//
//  Created by Ben Whittle on 1/23/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import AVFoundation
import Combine

class AVRecorder: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    enum Threads {
        static let control = "av-control"
        static let dataOutput = "av-data-output"
    }

    @Published var state = AVRecorderState.initialized
    
    let sessionFactory = AVSessionFactory()
    
    var session: AVCaptureSession?
    
    var startStatus = AVRecorderStartStatus()
    
    var avRecording: AVRecording?
    
    var recordingData: Data? { avRecording?.data }
    
    private lazy var controlThread = Thread.newBackgroundThread(name: Threads.control)
    
    private lazy var dataOutputThread = Thread.newBackgroundThread(name: Threads.dataOutput)

    func start(id: String) {
        controlThread.async {
            guard self.avRecording == nil else {
                return
            }

            self.createAVRecording()
            self.createSession()
            self.session!.startRunning()
            self.state = .starting(id: id, session: self.session!)
        }
    }
    
    func stop(id: String, cancelled: Bool = false) {
        controlThread.async {
            if self.avRecording == nil {
                return
            }

            self.state = .stopping(id: id, cancelled: cancelled)
        }
    }
    
    func clear() {
        avRecording = nil
    }
    
    private func createAVRecording() {
        avRecording = AVRecording()
    }
    
    private func stopSession(id: String, cancelled: Bool, lastFrame: NSImage?) {
        controlThread.async {
            if self.session == nil {
                return
            }
            
            self.state = .stopped(id: id, cancelled: cancelled, lastFrame: lastFrame)
            self.session!.stopRunning()
            self.session = nil
            self.startStatus = AVRecorderStartStatus()
        }
    }

    func isStarted() -> Bool {
        state == .started(id: "")
    }
    
    func isStopping() -> Bool {
        state == .stopping(id: "", cancelled: false)
    }
    
    // Handle any new AV output from the current capture session.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        switch output {
        
        // New audio output.
        case is AVCaptureAudioDataOutput:
            onAudioOutput(sampleBuffer: sampleBuffer, connection: connection)
            
        // New video output.
        case is AVCaptureVideoDataOutput:
            onVideoOutput(sampleBuffer: sampleBuffer, connection: connection)
            
        default:
            break
        }
    }
    
    private func shouldProcessOutput() -> Bool {
        isStarted() || isStopping()
    }
    
    private func onAudioOutput(sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection) {
        startStatus.audio = true
        
        checkIfFullyStarted()
        
        guard shouldProcessOutput() else {
            return
        }
        
        // append n shit
    }
    
    private func onVideoOutput(sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection) {
        startStatus.video = true
        
        checkIfFullyStarted()
        
        guard shouldProcessOutput() else {
            return
        }
        
        
        
        // HERE
        
        
        
        if isStopping() {
            stopWithLastFrame(sampleBuffer: sampleBuffer)
        }
    }
    
    private func stopWithLastFrame(sampleBuffer: CMSampleBuffer) {
        let (stoppingId, wasCancelled) = getStoppingAssociatedVals()
        
        guard let id = stoppingId, let cancelled = wasCancelled else {
            return
        }
        
        stopSession(
            id: id,
            cancelled: cancelled,
            lastFrame: imageFromBuffer(sampleBuffer)
        )
    }
    
    private func imageFromBuffer(_ sampleBuffer: CMSampleBuffer) -> NSImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        let attachments = CMCopyDictionaryOfAttachments(
            allocator: kCFAllocatorDefault,
            target: pixelBuffer,
            attachmentMode: CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)
        )
        
        let image = CIImage(
            cvImageBuffer: pixelBuffer,
            options: attachments as? [CIImageOption: Any]
        ).oriented(forExifOrientation: 9)
        
        return image.transformed(by: CGAffineTransform(scaleX: -1, y: 1)).nsImage
    }
    
    private func getStoppingAssociatedVals() -> (String?, Bool?) {
        switch state {
        case .stopping(id: let id, cancelled: let cancelled):
            return (id, cancelled)
        default:
            return (nil, nil)
        }
    }
    
    private func checkIfFullyStarted() {
        switch state {
        
        case .starting(id: let id, session: _):
            if startStatus.audio && startStatus.video {
                state = .started(id: id)
            }

        default:
            break
        }
    }
    
    private func createSession() {
        session = sessionFactory.createSession(
            outputDelegate: self,
            outputThread: dataOutputThread
        )
    }
}
