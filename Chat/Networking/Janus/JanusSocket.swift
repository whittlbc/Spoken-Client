//
//  JanusSocket.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import WebRTC
import Arrow

class JanusSocket: Socket {
        
    typealias IncomingMessage = [String: Any]
    
    static let defaultHeaders: [String: String] = [
        "Sec-WebSocket-Protocol": "janus-protocol"
    ]
    
    static let keepAliveInterval: TimeInterval = 30
    
    static func formatURL(host: String) -> String {
        return "ws://\(host):8188"
    }
    
    enum State: Int {
        case closed
        case open
        case create
        case attach
        case join
        case offer
        case error
    }
        
    var state: State?
    
    var plugin: String!
        
    var txs = [String: JanusTx]()
    
    var handles = [Int: JanusHandle]()
    
    var feeds = [Int: JanusHandle]()
    
    var sessionId: Int?
    
    weak var delegate: JanusSocketDelegate?

    private var keepAliveTimer: Timer?

    override init(url: String, headers: [String: String] = [:], requestTimeoutInterval: TimeInterval = 5) {
        super.init(url: url, headers: headers, requestTimeoutInterval: requestTimeoutInterval)
        
        // Start timer on repeat to keep socket connection alive.
        createKeepAliveTimer()
    }
    
    override func disconnect() {
        if isClosed() || isError() {
            return
        }
        
        super.disconnect()
    }
    
    func setState(_ state: State) {
        self.state = state
    }
    
    func isOpen() -> Bool {
        state == .open
    }
    
    func isClosed() -> Bool {
        state == .closed
    }
    
    func isError() -> Bool {
        state == .error
    }
    
    func sendMessage<T: Encodable>(_ message: T) {
        if let msg = serializeMessage(message) {
            webSocket.write(string: msg)
        }
    }
    
    func trickleCandidate(handleId: Int, candidate: RTCIceCandidate) {
        sendMessage(JanusTrickleCandidateMessage(
            sessionId: sessionId!,
            handleId: handleId,
            txId: JanusTx.newId(),
            iceCandidate: candidate
        ))
    }
    
    func trickleCandidateComplete(handleId: Int) {
        sendMessage(JanusTrickleCandidateCompleteMessage(
            sessionId: sessionId!,
            handleId: handleId,
            txId: JanusTx.newId()
        ))
    }
    
    func sendOffer(handleId: Int, sdp: RTCSessionDescription) {}
    
    func sendAnswer(handleId: Int, sdp: RTCSessionDescription) {}

    override func onConnected(headers: [String: String]) {
        // Set state to open.
        setState(.open)
        
        // Create a new Janus session.
        createSession()
    }
    
    override func onError(_ error: Error?) {
        delegate?.onSocketError(error)
    }
    
    override func onMessage(string: String) {
        // Deserialize message into JSON and obtain it's message type.
        guard let (messageType, json) = deserializeMessage(string: string) else {
            return
        }
        
        switch messageType {

        // Success message.
        case .success:
            onSuccessMessage(JanusTxResponseMessage.fromJSON(json))

        // Error message.
        case .error:
            onErrorMessage(JanusTxResponseMessage.fromJSON(json))

        // Event message.
        case .event:
            onEventMessage(json)

        // Detach message.
        case .detached:
            onDetachedMessage(JanusDetachedMessage.fromJSON(json))

        default:
            break
        }
    }
    
    private func onSuccessMessage(_ message: JanusTxResponseMessage) {
        // Get tx by id.
        guard message.hasTx, let tx = txs[message.txId] else {
            logger.warning("Janus success message handler: No tx found for id: \(message.txId)")
            return
        }
        
        // Call tx success handler.
        tx.onSuccess(message)
        
        // Remove tx from registry.
        txs.removeValue(forKey: tx.id)
    }
    
    private func onErrorMessage(_ message: JanusTxResponseMessage) {
        // Get tx by id.
        guard message.hasTx, let tx = txs[message.txId] else {
            logger.warning("Janus error message handler: No tx found for id: \(message.txId) -- \(message)")
            return
        }

        // Call tx error handler.
        tx.onError(message)
        
        // Remove tx from registry.
        txs.removeValue(forKey: tx.id)
    }
    
    func onEventMessage(_ json: JSON) {}
    
    private func onDetachedMessage(_ message: JanusDetachedMessage) {
        // Get handle for sender.
        guard message.hasSender, let handle = handles[message.sender] else {
            logger.warning("Janus detached message handler: No handle found for id: \(message.sender)")
            return
        }
        
        // Call handle leaving block.
        handle.onLeaving?()
    }
        
    private func onSessionCreationSuccess(_ message: JanusTxResponseMessage) {
        // Get session id from message data.
        guard message.hasDataId else {
            logger.error("Janus session creation succeeded but id returned was empty...\(message)")
            return
        }
        
        // Set session id.
        sessionId = message.dataId
        
        // Manually fire keep-alive timer.
        keepAliveTimer?.fire()
                
        // Attach to plugin to get handle.
        attachToPlugin { [weak self] msg in
            // Get handle id from message data.
            guard msg.hasDataId else {
                logger.error("Janus handle creation succeeded but id returned was empty...\(msg)")
                return
            }
            
            self?.onAttachedToPlugin(handleId: msg.dataId)
        }
    }
    
    func onAttachedToPlugin(handleId: Int) {}
            
    func attachToPlugin(then onSuccess: @escaping JanusTxBlock) {
        // Create new transaction to create a new handle.
        let tx = createTx(
            onSuccess: onSuccess,
            onError: { [weak self] message in
                self?.onHandleCreationError(message)
            }
        )
        
        // Send message to Janus.
        sendMessage(JanusAttachToPluginMessage(plugin: plugin, sessionId: sessionId!, txId: tx.id))
    }
    
    private func createSession() {
        // Create new transaction to create a new session.
        let tx = createTx(
            onSuccess: { [weak self] message in
                self?.onSessionCreationSuccess(message)
            },
            onError: { [weak self] message in
                self?.onSessionCreationError(message)
            }
        )
        
        // Send message to Janus.
        sendMessage(JanusCreateTxMessage(txId: tx.id))
    }
    
    func createHandle(
        id: Int,
        onRemoteJSEP: @escaping JanusRemoteJSEPBlock,
        feedId: Int? = nil,
        onJoined: JanusHandleBlock? = nil,
        onLeaving: JanusHandleBlock? = nil
    ) -> JanusHandle {
        // Create new handle.
        let handle = JanusHandle(
            id: id,
            onRemoteJSEP: onRemoteJSEP,
            feedId: feedId,
            onJoined: onJoined,
            onLeaving: onLeaving
        )
        
        // Store handle in handles registry.
        handles[handle.id] = handle
        
        return handle
    }
    
    func createTx(onSuccess: @escaping JanusTxBlock, onError: @escaping JanusTxBlock) -> JanusTx {
        // Create new tx.
        let tx = JanusTx(onSuccess: onSuccess, onError: onError)
        
        // Store tx in txs registry.
        txs[tx.id] = tx
        
        return tx
    }

    private func createKeepAliveTimer() {
        keepAliveTimer = Timer.scheduledTimer(
            timeInterval: JanusSocket.keepAliveInterval,
            target: self,
            selector: #selector(keepAlive),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc private func keepAlive() {
        guard let sessId = sessionId else {
            logger.warning("Not sending keep alive message -- sessionId not set yet.")
            return
        }
        
        sendMessage(JanusKeepAliveMessage(sessionId: sessId))
    }
    
    private func serializeMessage<T: Encodable>(_ message: T) -> String? {
        do {
            let jsonData = try JSONEncoder().encode(message)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            logger.error("Error encoding janus message as JSON: \(message)")
            return nil
        }
    }
    
    private func deserializeMessage(string: String) -> (JanusMessage.IncomingMessageType?, JSON)? {
        // Parse string into JSON object.
        guard let json = JSON(string), let data = json.data as? [String: Any] else {
            logger.error("Error parsing incoming Janus message as JSON: \(string)")
            return nil
        }

        // Parse Janus message type from data.
        guard let messageType = data[JanusMessage.Key.janus] as? String else {
            logger.error("No message type found at key \(JanusMessage.Key.janus) in message: \(data)")
            return nil
        }
        
        // Get incoming message type for value.
        let incomingMessageType = JanusMessage.IncomingMessageType(rawValue: messageType)
        
        // Return both the incoming message type and its json.
        return (incomingMessageType, json)
    }
    
    private func onSessionCreationError(_ message: JanusTxResponseMessage) {
        logger.error("Janus session creation failed: code=\(message.error.code), reason=\(message.error.reason).")
    }

    private func onHandleCreationError(_ message: JanusTxResponseMessage) {
        logger.error("Janus handle creation failed: code=\(message.error.code), reason=\(message.error.reason).")
    }
}
