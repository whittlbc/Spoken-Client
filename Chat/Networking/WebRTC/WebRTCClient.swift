//
//  WebRTCClient.swift
//  Chat
//
//  Created by Ben Whittle on 2/10/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import WebRTC

class WebRTCClient: NSObject, RTCPeerConnectionDelegate, JanusSocketDelegate {
    
    enum Stream {
        static let id = "SpokenLocalMediaStream"
    }
    
    enum Track {
        static let audioId = "SpokenAudioTrack"
        static let videoId = "SpokenVideoTrack"
    }
    
    private var videoSourceConfig: WebRTCVideoSourceConfig!
    
    private let factory = RTCPeerConnectionFactory.newDefaultFactory()
        
    private var peerConnections = [Int: JanusConnection]()
    
    private var publisherPeerConnection: RTCPeerConnection!
        
    private var localAudioTrack: RTCAudioTrack?
    
    private var localVideoTrack: RTCVideoTrack?
    
    private var videoCapturer: RTCVideoCapturer?

    private var signalingClient: JanusSocket!
    
    private var iceServers: [RTCIceServer] { [RTCIceServer(urlStrings: Config.iceServerURLs)] }
    
    private var publisherMediaConstraints: RTCMediaConstraints {
        getMediaConstraints()
    }
    
    private var offerMediaConstraints: RTCMediaConstraints {
        getMediaConstraints(receiveAudio: false, receiveVideo: false)
    }
    
    private var answerMediaConstraints: RTCMediaConstraints {
        getMediaConstraints(receiveAudio: false, receiveVideo: false)
    }
    
    private var audioTrackMediaConstraints: RTCMediaConstraints {
        getMediaConstraints()
    }
        
    required init(videoSourceConfig: WebRTCVideoSourceConfig) {
        super.init()
        
        // Store config to apply to local video track.
        self.videoSourceConfig = videoSourceConfig
        
        // Create publisher peer connection.
        createPublisherPeerConnection()
        
        // Configure audio session.
        configureAudioSession()

        // Create and connect to signaling server.
        createSignalingClient()
        
        // Create local audio stream.
        createLocalAudioStream()
        
        // Create local video stream.
        createLocalVideoStream()
    }
        
    func onPublisherJoined(_ handleId: Int?) {
        logger.debug("Publisher joined.")
    }
    
    func onPublisherRemoteJSEP(_ handleId: Int?, jsep: JanusJSEP?) {
        logger.debug("On publisher remote JSEP.")
    }
    
    func onSubscriberRemoteJSEP(_ handleId: Int?, jsep: JanusJSEP?) {
        logger.debug("On subscriber remote JSEP.")
    }
    
    func onSubscriberLeaving(_ handleId: Int?) {
        logger.debug("Subscriber is leaving.")
    }
    
    func onSocketError(_ error: Error?) {
        logger.error("WebRTC socket error: \(error?.describe() ?? "")")
    }
    
    func peerConnection(_: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        logger.debug("PeerConnection stateChanged: \(stateChanged)")
    }

    func peerConnection(_: RTCPeerConnection, didAdd _: RTCMediaStream) {
        logger.debug("PeerConnection did add stream")
    }

    func peerConnection(_: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        logger.debug("PeerConnection didRemove stream:\(stream)")
    }

    func peerConnectionShouldNegotiate(_: RTCPeerConnection) {
        logger.debug("PeerConnection should negotiate")
    }

    func peerConnection(_: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        logger.debug("PeerConnection RTCIceGatheringState:\(newState)")
    }

    func peerConnection(_: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        logger.debug("PeerConnection RTCIceConnectionState: \(newState)")
    }

    func peerConnection(_: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        logger.debug("PeerConnection didGenerate: \(candidate)")
    }

    func peerConnection(_: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        logger.debug("PeerConnection didRemove \(candidates)")
    }

    func peerConnection(_: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        logger.debug("PeerConnection didOpen \(dataChannel)")
    }
    
    private func createLocalAudioStream() {
        createLocalAudioTrack()
        publisherPeerConnection.add(localAudioTrack!, streamIds: [Stream.id])
    }

    private func createLocalVideoStream() {
        createLocalVideoTrack()
        publisherPeerConnection.add(localVideoTrack!, streamIds: [Stream.id])
    }
    
    private func createLocalAudioTrack() {
        // Create new audio source.
        let audioSource = factory.audioSource(with: audioTrackMediaConstraints)
        
        // Create local audio track from source.
        localAudioTrack = factory.audioTrack(with: audioSource, trackId: Track.audioId)
    }

    private func createLocalVideoTrack() {
        // Create new video source.
        let videoSource = factory.videoSource()
        
        // Apply video source config.
        videoSource.adaptOutputFormat(
            toWidth: Int32(videoSourceConfig.width),
            height: Int32(videoSourceConfig.height),
            fps: Int32(videoSourceConfig.fps)
        )
        
        // Create new video capturer with the new source as delegate.
        videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        
        // Create local video track from source.
        localVideoTrack = factory.videoTrack(with: videoSource, trackId: Track.videoId)
    }
    
    private func configureAudioSession() {
        // TODO: Anything to do here on mac?
        // You probably need to subscribe to audio route changes in here.
    }
    
    private func createPublisherPeerConnection() {
        publisherPeerConnection = factory.peerConnection(
            with: getPublisherRTCConfig(),
            constraints: publisherMediaConstraints,
            delegate: nil
        )
    }
    
    private func createSignalingClient() {
        // Use Janus as signaling server.
        signalingClient = JanusSocket()
        
        // Set delegate to self.
        signalingClient.delegate = self
        
        // Connect to Janus.
        signalingClient.connect()
    }
    
    private func getPublisherRTCConfig() -> RTCConfiguration {
        let config = RTCConfiguration()
        config.iceServers = iceServers
        config.iceTransportPolicy = .all
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        config.bundlePolicy = .maxBundle
        config.keyType = .ECDSA
        config.rtcpMuxPolicy = .require
        config.tcpCandidatePolicy = .enabled
        return config
    }
    
    private func getMediaConstraints(receiveAudio: Bool? = nil, receiveVideo: Bool? = nil) -> RTCMediaConstraints {
        var mandatoryConstraints = [String: String]()
        
        if let audio = receiveAudio {
            mandatoryConstraints[kRTCMediaConstraintsOfferToReceiveAudio] = formatMediaConstraintsBool(audio)
        }
        
        if let video = receiveVideo {
            mandatoryConstraints[kRTCMediaConstraintsOfferToReceiveVideo] = formatMediaConstraintsBool(video)
        }
        
        return RTCMediaConstraints(
            mandatoryConstraints: mandatoryConstraints.isEmpty ? nil : mandatoryConstraints,
            optionalConstraints: nil
        )
    }
    
    private func formatMediaConstraintsBool(_ value: Bool) -> String {
        value ? kRTCMediaConstraintsValueTrue : kRTCMediaConstraintsValueFalse
    }
}
