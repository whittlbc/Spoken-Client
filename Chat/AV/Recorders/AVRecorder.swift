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
    
    private var controlThread: DispatchQueue { getBackgroundThread(name: Threads.control) }
    
    private var dataOutputThread: DispatchQueue { getBackgroundThread(name: Threads.dataOutput) }
        
    func start(id: String) {
        controlThread.async {
            self.createSession()
            self.session!.startRunning()
            self.state = .starting(self.session!, id)
        }
    }
    
    func stop() {
        controlThread.async {
            self.state = .stopping
            self.session!.stopRunning()
            self.session = nil
            self.startStatus = AVRecorderStartStatus()
        }
    }
    
    func isStarted() -> Bool {
        state == .started("")
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
    
    private func onAudioOutput(sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection) {
        startStatus.audio = true
        
        checkIfFullyStarted()
        
        guard isStarted() else {
            return
        }
    }
    
    private func onVideoOutput(sampleBuffer: CMSampleBuffer, connection: AVCaptureConnection) {
        startStatus.video = true
        
        checkIfFullyStarted()
        
        guard isStarted() else {
            return
        }
    }
    
    private func checkIfFullyStarted() {
        switch state {
        
        case .starting(_, let id):
            if startStatus.audio && startStatus.video {
                state = .started(id)
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
    
    private func getBackgroundThread(name: String) -> DispatchQueue {
        dispatch_queue_global_t(
            label: [Config.appBundleID, name].joined(separator: "."),
            qos: .background
        )
    }
}
