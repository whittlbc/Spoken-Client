//
//  AudioSession.swift
//  Chat
//
//  Created by Ben Whittle on 1/5/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Speech

public enum AV {
            
    // Audio/video permissions manager.
    static var permissions = AVPermissions()
    
    // Audio/video stream manager.
    static let streamManager = StreamManager()

    // Seek audio/video permissions.
    static func seekPermissions() {
        AV.permissions.seekPermissions()
    }
    
    // Render the local stream to the provided video view.
    static func renderLocalStream(to videoView: VideoView) {
        streamManager.renderLocalStream(to: videoView)
    }
    
    // Start recording a new AV message.
    static func startRecordingMessage(_ message: Message) {
        streamManager.joinChannel(
            withId: message.id,
            token: message.token,
            uid: StreamConfig.recordingUserUid
        )
    }
    
    // Stop recording the active AV message.
    static func stopRecordingMessage() {
        streamManager.leaveChannel()
    }
    
    static func createMessagePlayer(message: Message) {
        streamManager.createMessagePlayer(message: message)
    }
    
    static func getMessagePlayer() -> AVPlayer? {
        streamManager.messagePlayer
    }
    
    static func playMessage() {
        streamManager.playMessage()
    }
}

class AVPermissions {
    
    enum AuthStatus {
        case unknown
        case denied
        case authed
    }
    
    var audioAuthStatus: AuthStatus = .unknown {
        didSet { onPermissionSet() }
    }
    
    var videoAuthStatus: AuthStatus = .unknown {
        didSet { onPermissionSet() }
    }
    
    var isAudioAuthed: Bool {
        switch audioAuthStatus {
        case .authed:
            return true
        default:
            return false
        }
    }
    
    var isVideoAuthed: Bool {
        switch videoAuthStatus {
        case .authed:
            return true
        default:
            return false
        }
    }
        
    func seekPermissions() {
        // Ask permission to access the mic.
        seekMicPermission()
        
        // Ask permission to use the camera if the user wants to use video.
        if UserSettings.Video.useCamera {
            seekCameraPermission()
        }
    }
    
    private func onPermissionSet() {
        if isAudioAuthed && isVideoAuthed {
            onFullyAuthed()
        }
    }
    
    private func onFullyAuthed() {
        // Initialize RTC kit.
        AV.streamManager.initializeRTCKit()
    }
    
    private func seekMicPermission() {
        // Switch over the current auth status for mic access.
        switch AVCaptureDevice.authorizationStatus(for: .audio) {

        // If already authorized, go ahead and configure the mic.
        case .authorized:
            audioAuthStatus = .authed
        
        // If user hasn't been asked yet, ask for permission.
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                self?.audioAuthStatus = granted ? .authed : .denied
            }
            
        // Log error if device restricts mic access.
        case .restricted:
            logger.error("Seeking mic permission failed -- device restricts mic access.")
            audioAuthStatus = .denied
        
        // Log error if user denies mic access.
        case .denied:
            logger.error("Seeking mic permission failed -- user denied access.")
            audioAuthStatus = .denied
        
        // Handle unknown cases that may arise in future versions.
        default:
            break
        }
    }

    private func seekCameraPermission() {
        // Switch over the current auth status for camera access.
        switch AVCaptureDevice.authorizationStatus(for: .video) {

        // If already authorized, go ahead and configure the inputs requiring camera access.
        case .authorized:
            videoAuthStatus = .authed
        
        // If user hasn't been asked yet, ask for permission.
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                self?.videoAuthStatus = granted ? .authed : .denied
            }
            
        // Log error if device restricts camera access.
        case .restricted:
            logger.error("Seeking camera permission failed -- device restricts camera access.")
            videoAuthStatus = .denied
        
        // Log error if user denies camera access.
        case .denied:
            logger.error("Seeking camera permission failed -- user denied access.")
            videoAuthStatus = .denied
        
        // Handle unknown cases that may arise in future versions.
        default:
            break
        }
    }
}
