//
//  AVStreamer.swift
//  Chat
//
//  Created by Ben Whittle on 2/7/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import AgoraRtcKit
import Combine

class StreamManager: NSObject, AgoraRtcEngineDelegate, AgoraVideoDataPluginDelegate {
    
    var camaraHasBeenTurnedOnBefore = false
            
    private var rtcKit: AgoraRtcEngineKit!
    
    private var mediaDataPlugin: AgoraMediaDataPlugin!
    
    private var videoSessions = [VideoSession]()
    
    private var lastVideoFrame: AgoraVideoRawData?
    
    private var messagePlayerItem: AVPlayerItem?
    
    private(set) var messagePlayer: AVPlayer?
    
    private var messagePlayerItemContext = 0
    
    private var messageToPlay: Message?
    
    weak var delegate: StreamManagerDelegate?
    
    func initializeRTCKit() {
        // Create new RTC kit instance.
        createRTCKit()
        
        // Set audio recording device.
        setAudioRecordingDevice()
        
        // Set audio playout device.
        setAudioRecordingDevice()

        // Set video capture device.
        setVideoCaptureDevice()

        // Enable live broadcast mode.
        enableLiveBroadcast()
        
        // Enable the video module.
        enableVideoModule()
        
        // Set the video configuration.
        setVideoConfig()

        // Set encryption type.
        setStreamEncryption()
        
        // Register media data plugin.
        registerMediaDataPlugin()
    }
    
    func renderLocalStream(to videoView: VideoView) {
        // Create a new local video session.
        let localSession = VideoSession.newLocalSession(videoView: videoView)
        
        // Add video session to list of active sessions.
        addSession(localSession)
        
        // Start local video preview.
        rtcKit.setupLocalVideo(localSession.videoCanvas)
        
        // Start the local video preview.
        rtcKit.startPreview()
    }
        
    func joinChannel(withId id: String, token: String, uid: UInt) {
        rtcKit.joinChannel(
            byToken: token,
            channelId: id,
            info: nil,
            uid: uid,
            joinSuccess: nil
        )
    }
    
    func leaveChannel() {
        // Release the local AgoraRtcVideoCanvas instance.
        rtcKit.setupLocalVideo(nil)

        // Leave the channel.
        rtcKit.leaveChannel(nil)
        
        // Stop the video preview.
        rtcKit.stopPreview()
        
        // Clear all video sessions.
        videoSessions.removeAll()
    }
    
    func createMessagePlayer(message: Message) {
        // Create AV asset.
        guard let asset = createAVAsset(forMessage: message) else {
            return
        }
        
        // Store this message as the most recent one to play.
        messageToPlay = message
        
        // Create message player item.
        createMessagePlayerItem(withAsset: asset)
        
        // Create message player.
        messagePlayer = AVPlayer(playerItem: messagePlayerItem)
    }
        
    func playMessage() {
        messagePlayer?.play()
    }
    
    func cacheLastVideoFrame() -> NSImage? {
        if let frame = lastVideoFrame, let pixelBuffer = mediaDataPlugin.rawVideoData(toPixelBuffer: frame) {
            return CIImage(cvPixelBuffer: pixelBuffer.takeRetainedValue())
                .oriented(forExifOrientation: 9)
                .transformed(by: CGAffineTransform(scaleX: -1, y: 1))
                .nsImage
        }
        
        return nil
    }
    
    // Occurs when the local user joins a specified channel.
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        logger.info("Joined channel: \(channel)")
    }
    
    // Occurs when the connection between the SDK and the server is interrupted.
    func rtcEngineConnectionDidInterrupted(_ engine: AgoraRtcEngineKit) {
        logger.warning("RTC connection interrupted")
    }
    
    // Occurs when the SDK cannot reconnect to Agora’s edge server 10 seconds after
    // its connection to the server is interrupted.
    func rtcEngineConnectionDidLost(_ engine: AgoraRtcEngineKit) {
        logger.warning("RTC connection lost")
    }
    
    // Reports an error during SDK runtime.
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        logger.error("RTC error code \(errorCode.rawValue)")
    }
    
    // Got first local video frame.
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstLocalVideoFrameWith size: CGSize, elapsed: Int) {
        delegate?.onVideoPreviewStarted()
    }
    
    // Local stats available.
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportRtcStats stats: AgoraChannelStats) {}
    
    // First remote video frame available.
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {}
    
    // Occurs when user goes offline.
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        if let index = getSessionIndex(forUid: uid) {
            removeSession(atIndex: index)
        }
    }
    
    // Video was muted.
    func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted: Bool, byUid uid: UInt) {}
    
    // Got remote video stats.
    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStats stats: AgoraRtcRemoteVideoStats) {}
    
    // Got remote audio stats.
    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteAudioStats stats: AgoraRtcRemoteAudioStats) {}
    
    // Occurs each time the SDK receives a video frame captured by the local camera.
    func mediaDataPlugin(
        _ mediaDataPlugin: AgoraMediaDataPlugin,
        didCapturedVideoRawData videoRawData: AgoraVideoRawData
    ) -> AgoraVideoRawData {
        lastVideoFrame = videoRawData
        return videoRawData
    }
    
    // Occurs each time the SDK receives a video frame before sending to encoder.
    func mediaDataPlugin(
        _ mediaDataPlugin: AgoraMediaDataPlugin,
        willPreEncode videoRawData: AgoraVideoRawData
    ) -> AgoraVideoRawData {
        return videoRawData
    }
    
    // Occurs each time the SDK receives a video frame sent by the remote user.
    func mediaDataPlugin(
        _ mediaDataPlugin: AgoraMediaDataPlugin,
        willRenderVideoRawData videoRawData: AgoraVideoRawData,
        ofUid uid: uint
    ) -> AgoraVideoRawData {
        return videoRawData
    }

    private func clearSessions() {
        videoSessions.removeAll()
    }
    
    private func addSession(_ session: VideoSession) {
        videoSessions.append(session)
    }
    
    private func removeSession(atIndex index: Int) {
        let session = videoSessions.remove(at: index)
        session.videoCanvas.view = nil
    }
    
    private func getSessionIndex(forUid uid: UInt) -> Int? {
        for (i, session) in videoSessions.enumerated() {
            if session.uid == uid {
                return i
            }
        }
        
        return nil
    }
    
    private func createRTCKit() {
        rtcKit = AgoraRtcEngineKit.sharedEngine(
            withAppId: Config.agoraAppID,
            delegate: self
        )
    }
    
    private func setAudioRecordingDevice() {
        if let deviceId = StreamConfig.audioRecordingDevice.id {
            rtcKit.setDevice(.audioRecording, deviceId: deviceId)
        }
    }
    
    private func setAudioPlayoutDevice() {
        if let deviceId = StreamConfig.audioPlayoutDevice.id {
            rtcKit.setDevice(.audioPlayout, deviceId: deviceId)
        }
    }

    private func setVideoCaptureDevice() {
        if let deviceId = StreamConfig.videoCaptureDevice.id {
            rtcKit.setDevice(.videoCapture, deviceId: deviceId)
        }
    }

    private func enableLiveBroadcast() {
        rtcKit.setChannelProfile(.liveBroadcasting)
        rtcKit.setClientRole(.broadcaster)
    }
    
    private func enableVideoModule() {
        rtcKit.enableVideo()
    }
    
    private func setVideoConfig() {
        rtcKit.setVideoEncoderConfiguration(StreamConfig.videoEncoderConfig)
    }
    
    private func setStreamEncryption() {
        // TODO: Come back to this.
    }
    
    private func registerMediaDataPlugin() {
        // Set up raw media data observers.
        mediaDataPlugin = AgoraMediaDataPlugin(agoraKit: rtcKit)
        
        // Register video observer.
        let videoType: ObserverVideoType = ObserverVideoType(rawValue: ObserverVideoType.captureVideo.rawValue | ObserverVideoType.renderVideo.rawValue | ObserverVideoType.preEncodeVideo.rawValue)
        
        mediaDataPlugin.registerVideoRawDataObserver(videoType)
        mediaDataPlugin.videoDelegate = self
    }
    
    private func createAVAsset(forMessage message: Message) -> AVAsset? {
        guard let url = message.getRecordingURL(), let cookies = message.getCookies() else {
            return nil
        }
        
        return AVURLAsset(
            url: url,
            options: ["AVURLAssetHTTPHeaderFieldsKey": HTTPCookie.requestHeaderFields(with: cookies)]
        )
    }
    
    private func createMessagePlayerItem(withAsset asset: AVAsset) {
        messagePlayerItem = AVPlayerItem(
            asset: asset,
            automaticallyLoadedAssetKeys: ["playable", "hasProtectedContent"]
        )
        
        // Register as an observer of the player item's status property
        messagePlayerItem!.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.status),
            options: [.old, .new],
            context: &messagePlayerItemContext
        )
    }
    
    private func onMessageReadyToPlay() {
        guard let message = messageToPlay else {
            logger.error("Message is ready to play, but messageToPlay is nil...")
            return
        }
        
        delegate?.onMessageReadyToPlay(message)
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        // Only handle observations for the messagePlayerItemContext.
        guard context == &messagePlayerItemContext else {
            super.observeValue(
                forKeyPath: keyPath,
                of: object,
                change: change,
                context: context
            )
            return
        }

        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }

            // Switch over status value
            switch status {
            
            // Player item is ready to play.
            case .readyToPlay:
                onMessageReadyToPlay()

            // Player item failed.
            case .failed:
                logger.error("Player item failed.")
                
            // Player item is not yet ready.
            case .unknown:
                break
            
            default:
                break
            }
        }
    }
}
