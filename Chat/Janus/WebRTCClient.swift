//
//  RTCClient.swift
//  Chat
//
//  Created by Ben Whittle on 2/6/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import WebRTC

protocol WebRTCClientDelegate: class {
    func webRTCClient(_ client: WebRTCClient, didGenerate candidate: RTCIceCandidate)
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState)
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data)
}

class WebRTCClient: NSObject, JanusSocketDelegate {
    
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        //support all codec formats for encode and decode
        return RTCPeerConnectionFactory(encoderFactory: RTCDefaultVideoEncoderFactory(),
                                        decoderFactory: RTCDefaultVideoDecoderFactory())
    }()

    weak var delegate: WebRTCClientDelegate?
    private let peerConnection: RTCPeerConnection

    // Accept video and audio from remote peer
    private let streamId = "KvsLocalMediaStream"
    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                                   kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue]
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    private var localAudioTrack: RTCAudioTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    private var remoteDataChannel: RTCDataChannel?
    private var constructedIceServers: [RTCIceServer]?

    var websocket: JanusSocket!
    
    var peerConnectionDict: [AnyHashable : JanusConnection]?
    
    var publisherPeerConnection: RTCPeerConnection? = nil
    
    required init(iceServers: [RTCIceServer], isAudioOn: Bool) {
        let config = RTCConfiguration()
        config.iceServers = iceServers
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        config.bundlePolicy = .maxBundle
        config.keyType = .ECDSA
        config.rtcpMuxPolicy = .require
        config.tcpCandidatePolicy = .enabled
                
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: nil)

        super.init()
//        configureAudioSession()
        
        websocket = JanusSocket()
        websocket.tryToConnect()
        websocket.delegate = self

        if (isAudioOn) {
            createLocalAudioStream()
        }
        
        createLocalVideoStream()
        peerConnection.delegate = self
    }
    
//    func configureAudioSession() {
//        let audioSession = RTCAudioSession.sharedInstance()
//        audioSession.isAudioEnabled = true
//
//        do {
//            try? audioSession.lockForConfiguration()
//            // NOTE : Can remove .defaultToSpeaker when not required.
//            try
//                audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with:.defaultToSpeaker)
//            try audioSession.setMode(AVAudioSessionModeDefault)
//            // NOTE : Can remove the following line when speaker not required.
//            try audioSession.overrideOutputAudioPort(.speaker)
//            //When passed in the options parameter of the setActive(_:options:) instance method, this option indicates that when your audio session deactivates, other audio sessions that had been interrupted by your session can return to their active state.
//            try? AVAudioSession.sharedInstance().setActive(true, with: .notifyOthersOnDeactivation)
//            audioSession.unlockForConfiguration()
//        } catch {
//          print("audioSession properties weren't set because of an error.")
//          print(error.localizedDescription)
//          audioSession.unlockForConfiguration()
//        }
//    }

    func shutdown() {
        peerConnection.close()

        if let stream = peerConnection.localStreams.first {
            localAudioTrack = nil
            localVideoTrack = nil
            remoteVideoTrack = nil
            peerConnection.remove(stream)
        }
    }

    func offer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(mandatoryConstraints: mediaConstrains,
                                             optionalConstraints: nil)
        peerConnection.offer(for: constrains) { sdp, _ in
            guard let sdp = sdp else {
                return
            }

            self.peerConnection.setLocalDescription(sdp, completionHandler: { _ in
                completion(sdp)
            })
        }
    }

    func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(mandatoryConstraints: mediaConstrains,
                                             optionalConstraints: nil)
        peerConnection.answer(for: constrains) { sdp, _ in
            guard let sdp = sdp else {
                return
            }

            self.peerConnection.setLocalDescription(sdp, completionHandler: { _ in
                completion(sdp)
            })
        }
    }

    func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> Void) {
        peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
    }

    func set(remoteCandidate: RTCIceCandidate) {
        peerConnection.add(remoteCandidate)
    }

    func startCaptureLocalVideo(renderer: RTCVideoRenderer) {
        guard let capturer = self.videoCapturer as? RTCCameraVideoCapturer else {
            return
        }
        
        let captureDevices = RTCCameraVideoCapturer.captureDevices()
        
        guard captureDevices.count > 0 else {
            return
        }
        
        let frontCamera = captureDevices[0]
        
        guard let format = RTCCameraVideoCapturer.supportedFormats(for: frontCamera).last else {
            return
        }
        
        guard let fps = format.videoSupportedFrameRateRanges.first?.maxFrameRate else {
            print(format.videoSupportedFrameRateRanges)
            return
        }

        capturer.startCapture(with: frontCamera,
                              format: format,
                              fps: Int(fps.magnitude))
        
        print("got capturer with FPS: \(Int(fps.magnitude))")
        
        localVideoTrack?.add(renderer)
    }

    func renderRemoteVideo(to renderer: RTCVideoRenderer) {
        remoteVideoTrack?.add(renderer)
    }

    private func createLocalVideoStream() {
        localVideoTrack = createVideoTrack()

        if let localVideoTrack = localVideoTrack {
            peerConnection.add(localVideoTrack, streamIds: [streamId])
            remoteVideoTrack = peerConnection.transceivers.first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
        }
    }

    private func createLocalAudioStream() {
        localAudioTrack = createAudioTrack()
        if let localAudioTrack  = localAudioTrack {
            peerConnection.add(localAudioTrack, streamIds: [streamId])
            let audioTracks = peerConnection.transceivers.compactMap { $0.sender.track as? RTCAudioTrack }
            audioTracks.forEach { $0.isEnabled = true }
        }
    }

    private func createVideoTrack() -> RTCVideoTrack {
        let videoSource = WebRTCClient.factory.videoSource()
        videoSource.adaptOutputFormat(toWidth: 1280, height: 720, fps: 30)
        videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        return WebRTCClient.factory.videoTrack(with: videoSource, trackId: "KvsVideoTrack")
    }

    private func createAudioTrack() -> RTCAudioTrack {
        let mediaConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = WebRTCClient.factory.audioSource(with: mediaConstraints)
        return WebRTCClient.factory.audioTrack(with: audioSource, trackId: "KvsAudioTrack")
    }
    
    func onPublisherJoined(_ handleId: NSNumber?) {
        
    }
    
    func onPublisherRemoteJsep(_ handleId: NSNumber?, dict jsep: [AnyHashable : Any]?) {
        
    }
    
    func subscriberHandleRemoteJsep(_ handleId: NSNumber?, dict jsep: [AnyHashable : Any]?) {
        
    }
    
    func onLeaving(_ handleId: NSNumber?) {
        
    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    func peerConnection(_: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        debugPrint("peerConnection stateChanged: \(stateChanged)")
    }

    func peerConnection(_: RTCPeerConnection, didAdd _: RTCMediaStream) {
        debugPrint("peerConnection did add stream")
    }

    func peerConnection(_: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        debugPrint("peerConnection didRemove stream:\(stream)")
    }

    func peerConnectionShouldNegotiate(_: RTCPeerConnection) {
        debugPrint("peerConnectionShouldNegotiate")
    }

    func peerConnection(_: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        debugPrint("peerConnection RTCIceGatheringState:\(newState)")
    }

    func peerConnection(_: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        debugPrint("peerConnection RTCIceConnectionState: \(newState)")
        delegate?.webRTCClient(self, didChangeConnectionState: newState)
    }

    func peerConnection(_: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        debugPrint("peerConnection didGenerate: \(candidate)")
        delegate?.webRTCClient(self, didGenerate: candidate)
    }

    func peerConnection(_: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        debugPrint("peerConnection didRemove \(candidates)")
    }

    func peerConnection(_: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        debugPrint("peerConnection didOpen \(dataChannel)")
        remoteDataChannel = dataChannel
    }
}

extension WebRTCClient: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        debugPrint("dataChannel didChangeState: \(dataChannel.readyState)")
    }

    func dataChannel(_: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        delegate?.webRTCClient(self, didReceiveData: buffer.data)
    }
}
