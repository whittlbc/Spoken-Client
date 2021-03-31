//
//  JanusRecordPlaySocket.swift
//  Chat
//
//  Created by Ben Whittle on 3/17/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import WebRTC
import Arrow

class JanusRecordPlaySocket: JanusSocket {
    
    enum Action {
        case record
        case play
    }
    
    // Id of recording to either record or play.
    var recordingId: Int!
    
    var action: Action!
    
    convenience init(url: String, recordingId: Int, action: Action) {
        self.init(url: url, headers: JanusSocket.defaultHeaders)
        
        // Set recording id.
        self.recordingId = recordingId
        
        // Store whether to record or play.
        self.action = action

        // Set plugin to videoroom.
        self.plugin = JanusMessage.Key.recordPlayPlugin
    }
    
    override init(url: String, headers: [String: String] = [:], requestTimeoutInterval: TimeInterval = 5) {
        super.init(url: url, headers: headers, requestTimeoutInterval: requestTimeoutInterval)
    }
    
    func isRecord() -> Bool {
        action == .record
    }
    
    func isPlay() -> Bool {
        action == .play
    }
    
    private func sendPlayRequest() {
        
    }
                
    override func sendOffer(handleId: Int, sdp: RTCSessionDescription) {
        sendMessage(JanusRecordPlayPublisherOfferMessage(
            sessionId: sessionId!,
            handleId: handleId,
            txId: JanusTx.newId(),
            jsep: JanusJSEP(sdp: sdp),
            requestType: .record,
            recordingId: recordingId
        ))
    }
    
    override func sendAnswer(handleId: Int, sdp: RTCSessionDescription) {
//        sendMessage(JanusSubscriberAnswerMessage(
//            sessionId: sessionId!,
//            handleId: handleId,
//            txId: JanusTx.newId(),
//            jsep: JanusJSEP(sdp: sdp),
//            requestType: .start,
//            id: recordingId
//        ))
    }
    
    override func onEventMessage(_ json: JSON) {
        // Create recordplay event message from json.
        let message = JanusRecordPlayEventMessage.fromJSON(json)

        // Handle remote JSEP if provided.
        if message.hasJSEP {
            onRemoteJSEP(message: message)
        }
    }
    
    override func onAttachedToPlugin(handleId: Int) {
        // Store new plugin handle.
        let handle = createHandle(
            id: handleId,
            onRemoteJSEP: { [weak self] jsep in
                self?.delegate?.onPublisherRemoteJSEP(handleId: handleId, jsep: jsep)
            },
            onJoined: { [weak self] in
                self?.delegate?.onPublisherJoined(handleId: handleId)
            }
        )
        
        // Configure AV.
        configureAVParams(handleId: handleId)
        
        // Register handle as joined.
        handle.onJoined!()
    }
    
    private func onJoined(handleId: Int) {
//        isPlay() ? sendPlayRequest(handleId: handleId) : delegate?.onPublisherJoined(handleId: handleId)
    }
    
    private func onRemoteJSEP(message: JanusRecordPlayEventMessage) {
        // Get handle for sender.
        guard message.hasSender, let handle = handles[message.sender] else {
            logger.warning("Janus handle onRemoteJSEP but no handle found for id: \(message.sender) -- \(message)")
            return
        }
        
        // Call remote JSEP block.
        handle.onRemoteJSEP(message.jsep)
    }
    
    private func configureAVParams(handleId: Int) {
        sendMessage(JanusRecordPlayConfigureAVMessage(
            sessionId: sessionId!,
            handleId: handleId,
            txId: JanusTx.newId(),
            requestType: .configure,
            videoBitrateMax: 1024 * 1024,
            videoKeyframeInterval: 15000
        ))
    }
}
