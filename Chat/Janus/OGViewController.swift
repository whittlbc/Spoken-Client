//
//  ViewController.swift
//  Janus-Video-Room
//
//  Created by Amirali Asvadi on 4/2/20.
//  Copyright © 2020 Amirali Asvadi. All rights reserved.
//

import Cocoa
import WebRTC

private let kARDMediaStreamId = "ARDAMS"
private let kARDAudioTrackId = "ARDAMSa0"
private let kARDVideoTrackId = "ARDAMSv0"

class ViewController: NSViewController, RTCPeerConnectionDelegate, JanusSocketDelegate {

    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        
        //support all codec formats for encode and decode
        return RTCPeerConnectionFactory(
            encoderFactory: RTCDefaultVideoEncoderFactory(),
            decoderFactory: RTCDefaultVideoDecoderFactory()
        )
    }()
    
//    @IBOutlet weak var localView: RTCMTLNSVideoView!
//    @IBOutlet weak var remoteView: RTCMTLNSVideoView!

    var websocket: JanusSocket!
    
    var peerConnectionDict = [AnyHashable : JanusConnection]()
    var publisherPeerConnection: RTCPeerConnection? = nil
    
    var localTrack: RTCVideoTrack? = nil
    var localAudioTrack: RTCAudioTrack? = nil

    var saveId: Int?
    var videoCheck: NSNumber?

    override class func awakeFromNib() {
        RTCInitializeSSL();
        RTCSetupInternalTracer();
    }

    override func viewDidLoad() {
        // TODO: Figure out what the equivalent of this is on macOS.
//        NotificationCenter.default.addObserver(self, selector: #selector(didSessionRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
        
        setSpeakerStates(enabled: true)
        
        websocket = JanusSocket()
        websocket.connect()
        websocket.delegate = self
        
        localTrack = createLocalVideoTrack()
        localAudioTrack = createLocalAudioTrack()
        videoCheck = NSNumber(value: true)
    }

    @IBAction func videoButtonTapped(_ sender: Any) {
        self.offerPeerConnectionAgain(videoCheck)
        if(videoCheck == NSNumber(value: true)){
            videoCheck = NSNumber(value: false)
        }else{
            videoCheck = NSNumber(value: true)
        }
    }

    func createLocalVideoTrack() -> RTCMTLNSVideoView? {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)

        let source = ViewController.factory.avFoundationVideoSource(with: cameraConstraints)
        let localVideoTrack = ViewController.factory.videoTrack(with: source!, trackId: kARDVideoTrackId)
//        localView.captureSession = source?.captureSession
        return localVideoTrack
    }

//    func currentMediaConstraint() -> [AnyHashable : Any]? {
//        var mediaConstraintsDictionary: [AnyHashable : Any]? = nil
//        let widthConstraint = "500"
//        let heightConstraint = "500"
//        let frameRateConstrait = "20"
//        if widthConstraint != "" && heightConstraint != "" {
//            mediaConstraintsDictionary = [
//            kRTCMediaConstraintsMinWidth: widthConstraint,
//            kRTCMediaConstraintsMaxWidth : widthConstraint,
//            kRTCMediaConstraintsMinHeight: heightConstraint,
//            kRTCMediaConstraintsMaxHeight : heightConstraint,
//            kRTCMediaConstraintsMaxFrameRate: frameRateConstrait
//            ]
//        }
//        return mediaConstraintsDictionary
//    }

//    func defaultMediaAudioConstraints() -> RTCMediaConstraints? {
//        let mandatoryConstraints = [
//            kRTCMediaConstraintsLevelControl: kRTCMediaConstraintsValueFalse
//        ]
//        let constraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
//        return constraints
//        return nil
//    }

    func createLocalAudioTrack() -> RTCAudioTrack? {
        let constraints = defaultMediaAudioConstraints()
        let source = ViewController.factory.audioSource(with: constraints)
        let track = ViewController.factory.audioTrack(with: source, trackId: kARDAudioTrackId)
        return track
    }

//    func createRemoteView() -> RTCMTLNSVideoView? {
//        remoteView.delegate = self
//        return remoteView
//    }

    func createPublisherPeerConnection() {
        publisherPeerConnection = createPeerConnection()
        createAudioSender(publisherPeerConnection)
        createVideoSender(publisherPeerConnection)
    }
    
//    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
//        var rect = videoView.frame
//        rect.size = size
//        print(String(format: "========didChangeVideiSize %fx%f", size.width, size.height))
//        videoView.frame = rect
//    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("=========didAddStream")
        var janusConnection: JanusConnection?
        for key in peerConnectionDict {
            let jc:JanusConnection = key.value
            if peerConnection == jc.connection {
                janusConnection = jc
                break
            }
        }
        print("=========didAddStream")
        print(stream.videoTracks.count)
        DispatchQueue.main.async(execute: {
            if stream.videoTracks.count != 0{
                let remoteVideoTrack = stream.videoTracks[0]
                let remoteView = self.createRemoteView()
                remoteVideoTrack.add(remoteView!)
                janusConnection?.videoTrack = remoteVideoTrack
                janusConnection?.videoView = remoteView
            }
        })
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("=========didRemoveStream");
    }


    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("=========didRemoveIceCandidates");
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        let sdp = candidate.sdp
        print("=========didGenerateIceCandidate==\(sdp)")
        var handleId: Int?
        for key in peerConnectionDict {
            let jc:JanusConnection = key.value
            if peerConnection == jc.connection {
                handleId = jc.handleId
                break
            }
        }
        if candidate != nil {
            websocket.trickleCandidate(handleId, candidate: candidate)
        } else {
            websocket.trickleCandidateComplete(handleId)
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
    }

    func createAudioSender(_ peerConnection: RTCPeerConnection?) -> RTCRtpSender? {
        let sender = peerConnection?.sender(withKind: kRTCMediaStreamTrackKindAudio, streamId: kARDMediaStreamId)
        if (localAudioTrack != nil) {
            sender?.track = localAudioTrack
        }
        return sender
    }

    func createVideoSender(_ peerConnection: RTCPeerConnection?) -> RTCRtpSender? {
        let sender = peerConnection?.sender(withKind: kRTCMediaStreamTrackKindVideo, streamId: kARDMediaStreamId)
        if (localTrack != nil) {
            sender?.track = localTrack
        }
        return sender
    }

    func createPeerConnection() -> RTCPeerConnection? {
        let constraints = defaultPeerConnectionConstraints()
        let config = RTCConfiguration()
        let iceServers = [defaultSTUNServer()!]
        config.iceServers = iceServers
        config.iceTransportPolicy = RTCIceTransportPolicy.all
        let peerConnection = ViewController.factory.peerConnection(with: config, constraints: constraints!, delegate: self)
        return peerConnection
    }

    func defaultSTUNServer() -> RTCIceServer? {
        let array = ["stun:stun.l.google.com:19302"]
        return RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
    }

    func defaultPeerConnectionConstraints() -> RTCMediaConstraints? {
        let optionalConstraints = [
            "DtlsSrtpKeyAgreement": "true"
        ]
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: optionalConstraints)
        return constraints
    }

    @objc func didSessionRouteChange(_ notification: Notification?) {
        guard let info = notification?.userInfo,
        let value = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: value) else {
                return
        }
        switch reason {
        case .categoryChange:
            try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        default:
            break
        }
    }

    func setSpeakerStates(enabled: Bool)
    {
        let session = AVAudioSession.sharedInstance()
        var _: Error?
        try? session.setCategory(AVAudioSession.Category.playAndRecord)
        try? session.setMode(AVAudioSession.Mode.voiceChat)
        if enabled {
            try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        } else {
            try? session.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
        }
        try? session.setActive(true)
    }

    func onPublisherJoined(_ handleId: Int?) {
        offerPeerConnection(handleId)
    }

    func offerPeerConnection(_ handleId: Int?) {
        createPublisherPeerConnection()
        saveId = handleId
        let jc = JanusConnection()
        jc.connection = publisherPeerConnection
        jc.handleId = handleId
        if let handleId = handleId {
            peerConnectionDict[handleId] = jc
        }
        publisherPeerConnection!.offer(for: defaultOfferConstraints()!, completionHandler: { sdp, error in
            self.publisherPeerConnection!.setLocalDescription(sdp!, completionHandler: { error in
                if(self.videoCheck == NSNumber(value: true)){
                    self.websocket.publisherCreateOffer(handleId, sdp: sdp!,hasVideo: NSNumber(value: false))
                }else{
                    self.websocket.publisherCreateOffer(handleId, sdp: sdp!,hasVideo: NSNumber(value: true))
                }
            })
        })
    }

//    func offerPeerConnectionAgain(_ hasVideo:NSNumber?) {
//        createPublisherPeerConnection()
//        let jc = JanusConnection()
//        jc.connection = publisherPeerConnection
//        jc.handleId = saveId
//        peerConnectionDict[saveId] = jc
//        publisherPeerConnection!.offer(for: defaultOfferConstraints()!, completionHandler: { sdp, error in
//            self.publisherPeerConnection!.setLocalDescription(sdp!, completionHandler: { error in
//                self.websocket.publisherCreateOffer(self.saveId, sdp: sdp!,hasVideo: hasVideo)
//            })
//        })
//    }

    func defaultOfferConstraints() -> RTCMediaConstraints? {
        let mandatoryConstraints = [
            "OfferToReceiveAudio": "false",
            "OfferToReceiveVideo": "false"
        ]
        let constraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        return constraints
    }
    
    func onPublisherRemoteJSEP(_ handleId: Int?, jsep: JanusJSEP?) {
        var jc: JanusConnection? = nil
        if let handleId = handleId {
            jc = peerConnectionDict[handleId]
        }
        let answerDescription = RTCSessionDescription(fromJSONDictionary: jsep)!
        jc?.connection!.setRemoteDescription(answerDescription, completionHandler: { error in
        })
    }

    func onSubscriberRemoteJSEP(_ handleId: Int?, jsep: JanusJSEP?) {
        let peerConnection = createPeerConnection()
        let jc = JanusConnection()
        jc.connection = peerConnection
        jc.handleId = handleId
        if let handleId = handleId {
            peerConnectionDict[handleId] = jc
        }
        
        let answerDescription = RTCSessionDescription(fromJSONDictionary: jsep)
        peerConnection?.setRemoteDescription(answerDescription!, completionHandler: { error in
        })
        let mandatoryConstraints = [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true"
        ]
        let constraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        peerConnection!.answer(for: constraints, completionHandler: { sdp, error in
            peerConnection!.setLocalDescription(sdp!, completionHandler: { error in
            })
            self.websocket.subscriberCreateAnswer(handleId, sdp: sdp)
        })
    }

    func onSubscriberLeaving(_ handleId: Int?) {
        var jc: JanusConnection? = nil
        if let handleId = handleId {
            jc = peerConnectionDict[handleId]
        }
        jc?.connection!.close()
        jc?.connection = nil
        var videoTrack = jc?.videoTrack
        videoTrack?.remove(jc?.videoView! as! RTCVideoRenderer)
        videoTrack = nil
        jc?.videoView!.renderFrame(nil)
        jc?.videoView!.removeFromSuperview()
        peerConnectionDict.removeValue(forKey: handleId)
    }

    func onSocketError(_ error: Error?) {
        
    }
}

