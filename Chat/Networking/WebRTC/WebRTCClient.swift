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
        
    private var connections = [Int: JanusConnection]()
    
    private var publisherPeerConnection: RTCPeerConnection!
        
    private var localAudioTrack: RTCAudioTrack?
    
    private var localVideoTrack: RTCVideoTrack?
    
    private var videoCapturer: RTCVideoCapturer?

    private var signalingClient: JanusSocket!
    
    private var iceServers: [RTCIceServer] { [RTCIceServer(urlStrings: Config.iceServerURLs)] }
    
    private var publisherMediaConstraints: RTCMediaConstraints {
        getMediaConstraints()
    }
    
    private var peerMediaConstraints: RTCMediaConstraints {
        getMediaConstraints()
    }
    
    private var offerMediaConstraints: RTCMediaConstraints {
        getMediaConstraints(receiveAudio: true, receiveVideo: true)
    }
    
    private var answerMediaConstraints: RTCMediaConstraints {
        getMediaConstraints(receiveAudio: true, receiveVideo: true)
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
        
    func onPublisherJoined(handleId: Int) {
        logger.debug("Publisher joined.")
        
        // Handle publisher joining room.
        handlePublisherJoined(handleId: handleId)
    }
    
    func onPublisherRemoteJSEP(handleId: Int, jsep: JanusJSEP?) {
        logger.debug("On publisher remote JSEP")
        
        // Handle publisher remote JSEP.
        handlePublisherRemoteJSEP(handleId: handleId, jsep: jsep)
    }
    
    func onSubscriberRemoteJSEP(handleId: Int, jsep: JanusJSEP?) {
        logger.debug("On subscriber remote JSEP")
        
        // Handle subscriber remote JSEP.
        handleSubscriberRemoteJSEP(handleId: handleId, jsep: jsep)
    }
    
    func onSubscriberLeaving(handleId: Int) {
        logger.debug("Subscriber is leaving.")
        
        // Handle subscriber leaving room.
        handleSubscriberLeaving(handleId: handleId)
    }
    
    func onSocketError(_ error: Error?) {
        logger.error("WebRTC socket error: \(error?.describe() ?? "")")
    }
    
    func peerConnection(_: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        logger.debug("PeerConnection signaling state changed: \(stateChanged)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        logger.debug("PeerConnection added stream: \(stream)")
        
        // Handle newly added remote stream.
        onRemoteStreamAdded(stream, by: peerConnection)
    }

    func peerConnection(_: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        logger.debug("PeerConnection removed stream: \(stream)")
    }

    func peerConnectionShouldNegotiate(_: RTCPeerConnection) {
        logger.debug("PeerConnection should negotiate")
    }

    func peerConnection(_: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        logger.debug("PeerConnection changed RTCIceGatheringState: \(newState)")
    }

    func peerConnection(_: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        logger.debug("PeerConnection changed RTCIceConnectionState: \(newState)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        logger.debug("PeerConnection generated ICE candidate: \(candidate)")
        
        // Handle newly generated ICE candidate.
        onICECandidateGenerated(candidate, by: peerConnection)
    }

    func peerConnection(_: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        logger.debug("PeerConnection removed ICE candidates: \(candidates)")
    }

    func peerConnection(_: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        logger.debug("PeerConnection opened data channel: \(dataChannel)")
    }
    
    private func handlePublisherJoined(handleId: Int) {
        // Create new connection with the publisher peer connection.
        _ = createConnection(handleId: handleId, peerConnection: publisherPeerConnection)
        
        // Offer publisher peer connection.
        offerPeerConnection(publisherPeerConnection, handleId: handleId)
    }

    private func handlePublisherRemoteJSEP(handleId: Int, jsep: JanusJSEP?) {
        // Get connection for handleId and ensure JSEP exists.
        guard let connection = connections[handleId], let jsep = jsep else {
            logger.error("Both connection and JSEP required to set remote desc: handleId=\(handleId)")
            return
        }

        // Set remote description for peer connection.
        setRemoteDescription(JanusMessage.newSDP(fromJSEP: jsep), forPeerConnection: connection.peerConnection) {}
    }
    
    private func handleSubscriberRemoteJSEP(handleId: Int, jsep: JanusJSEP?) {
        // Ensure JSEP exists.
        guard let jsep = jsep else {
            logger.error("JSEP required top set remote desc: handleId=\(handleId)")
            return
        }

        // Create a new connection with the given handle.
        let connection = createConnection(handleId: handleId)

        // Set remote description for new peer connection.
        setRemoteDescription(JanusMessage.newSDP(fromJSEP: jsep), forPeerConnection: connection.peerConnection) {}

        // Answer peer connection.
        answerPeerConnection(connection.peerConnection, handleId: handleId)
    }
    
    private func handleSubscriberLeaving(handleId: Int) {
        // Get connection for handleId.
        guard let connection = connections[handleId] else {
            logger.error("No connection found for handleId: \(handleId)")
            return
        }
        
        // Close peer connection and deallocate it.
        connection.peerConnection.close()
        connection.peerConnection = nil

//        if let videoTrack = connection.videoTrack {
//            // TODO: Remove any RTCVideoRenderer instances from video track
//        }
        
        // Remove connection from connections registry.
        connections.removeValue(forKey: handleId)
    }

    // Set remote description of peer connection.
    private func setRemoteDescription(
        _ sdp: RTCSessionDescription,
        forPeerConnection peerConnection: RTCPeerConnection,
        then onSuccess: @escaping () -> Void
    ) {
        peerConnection.setRemoteDescription(sdp, completionHandler: { error in
            if let err = error {
                logger.error("Error setting remote description: \(err)")
            }
            
            // Call success handler.
            onSuccess()
        })
    }
    
    // Set local description of peer connection.
    private func setLocalDescription(
        _ sdp: RTCSessionDescription,
        forPeerConnection peerConnection: RTCPeerConnection,
        then onSuccess: @escaping () -> Void
    ) {
        peerConnection.setLocalDescription(sdp, completionHandler: { error in
            if let err = error {
                logger.error("Error setting local description: \(err)")
            }
            
            // Call success handler.
            onSuccess()
        })
    }
    
    private func onRemoteStreamAdded(_ stream: RTCMediaStream, by peerConnection: RTCPeerConnection) {
        // Find connection with matching peer connections.
        guard let connection = getConnection(for: peerConnection) else {
            logger.error("No connection found for peer connection.")
            return
        }
        
        // Ensure at least one video track exists.
        guard stream.videoTracks.count > 0 else {
            logger.debug("Stream added but no video tracks exist.")
            return
        }
        
        // Add video track to janus connection.
        connection.videoTrack = stream.videoTracks[0]
    }
    
    private func onICECandidateGenerated(_ candidate: RTCIceCandidate, by peerConnection: RTCPeerConnection) {
        // Find connection with matching peer connections.
        guard let connection = getConnection(for: peerConnection) else {
            logger.error("No connection found for peer connection.")
            return
        }
        
        // Trickle the candidate.
        signalingClient.trickleCandidate(handleId: connection.handleId, candidate: candidate)
    }
    
    private func offerPeerConnection(_ peerConnection: RTCPeerConnection, handleId: Int) {
        peerConnection.offer(for: offerMediaConstraints) { sdp, error in
            if let err = error {
                logger.error("Error offering peer connection: \(err)")
                return
            }
            
            guard let sdp = sdp else {
                logger.error("No SDP returned when offering peer connection.")
                return
            }

            // Set local description and create publisher offer.
            self.setLocalDescription(sdp, forPeerConnection: peerConnection) {
                self.signalingClient.createPublisherOffer(handleId: handleId, sdp: sdp, hasVideo: true)
            }
        }
    }
    
    private func answerPeerConnection(_ peerConnection: RTCPeerConnection, handleId: Int) {
        peerConnection.answer(for: answerMediaConstraints) { sdp, error in
            if let err = error {
                logger.error("Error answering peer connection: \(err)")
                return
            }
            
            guard let sdp = sdp else {
                logger.error("No SDP returned when answering peer connection.")
                return
            }

            // Set local description and create subscriber answer.
            self.setLocalDescription(sdp, forPeerConnection: peerConnection) {
                self.signalingClient.createSubscriberAnswer(handleId: handleId, sdp: sdp)
            }
        }
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
            with: getPeerRTCConfig(),
            constraints: publisherMediaConstraints,
            delegate: nil
        )
    }
    
    private func createPeerConnection() -> RTCPeerConnection {
        return factory.peerConnection(
            with: getPeerRTCConfig(),
            constraints: peerMediaConstraints,
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
    
    private func createConnection(handleId: Int, peerConnection: RTCPeerConnection? = nil) -> JanusConnection {
        // Create a new connection.
        let connection = JanusConnection(
            handleId: handleId,
            peerConnection: peerConnection ?? createPeerConnection()
        )
        
        // Register connection inside connections map.
        connections[handleId] = connection
        
        return connection
    }
    
    private func getConnection(for peerConnection: RTCPeerConnection) -> JanusConnection? {
        for (_, connection) in connections {
            if connection.peerConnection == peerConnection {
                return connection
            }
        }
        
        return nil
    }
    
    private func getPeerRTCConfig() -> RTCConfiguration {
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
