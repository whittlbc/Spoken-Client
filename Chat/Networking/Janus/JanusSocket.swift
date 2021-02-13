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
    
    var roomId: Int!

    weak var delegate: JanusSocketDelegate?
    
    private var txs = [String: JanusTx]()
    
    private var handles = [Int: JanusHandle]()
    
    private var feeds = [Int: JanusHandle]()
    
    private var sessionId: Int?
    
    private var keepAliveTimer: Timer?

    convenience init(roomId: Int) {
        self.init(url: Config.janusURL, headers: JanusSocket.defaultHeaders)
        
        // Set video room id to connect to.
        self.roomId = roomId
        
        // Start timer on repeat to keep socket connection alive.
        createKeepAliveTimer()
    }
    
    override init(url: String, headers: [String: String] = [:], requestTimeoutInterval: TimeInterval = 5) {
        super.init(url: url, headers: headers, requestTimeoutInterval: requestTimeoutInterval)
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
    
    func sendMessage(_ message: JanusMessage) {
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
    
    func createPublisherOffer(handleId: Int, sdp: RTCSessionDescription, hasVideo: Bool) {
        sendMessage(JanusPublisherOfferMessage(
            sessionId: sessionId!,
            handleId: handleId,
            txId: JanusTx.newId(),
            jsep: JanusMessage.newJSEP(fromSDP: sdp),
            requestType: .configure,
            audio: true,
            video: hasVideo
        ))
    }
    
    func createSubscriberAnswer(handleId: Int, sdp: RTCSessionDescription) {
        sendMessage(JanusSubscriberAnswerMessage(
            sessionId: sessionId!,
            handleId: handleId,
            txId: JanusTx.newId(),
            jsep: JanusMessage.newJSEP(fromSDP: sdp),
            requestType: .start,
            room: roomId
        ))
    }

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
            onEventMessage(JanusEventMessage.fromJSON(json))

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
    
    private func onEventMessage(_ message: JanusEventMessage) {
        // If new videoroom handle joined, register it as having joined.
        if message.handleDidJoin {
            onHandleJoined(message: message)
        }
        
        // If any new remote publishers exist, subscribe to them.
        if message.hasPublishers {
            onPublishersAvailable(message.publishers)
        }
        
        // If videoroom handle left, register it as having left.
        if message.feedDidLeave {
            onLeavingFeed(withId: message.leavingFeedId)
        }
        
        // Handle remote JSEP if provided.
        if message.hasJSEP {
            onRemoteJSEP(message: message)
        }
    }
    
    private func onDetachedMessage(_ message: JanusDetachedMessage) {
        // Get handle for sender.
        guard message.hasSender, let handle = handles[message.sender] else {
            logger.warning("Janus detached message handler: No handle found for id: \(message.sender)")
            return
        }
        
        // Call handle leaving block.
        handle.onLeaving?()
    }
    
    private func onHandleJoined(message: JanusEventMessage) {
        // Get handle for sender.
        guard message.hasSender, let handle = handles[message.sender] else {
            logger.warning("Janus handle joined videoroom but no handle found for id: \(message.sender) -- \(message)")
            return
        }
        
        // Call handle leaving block.
        handle.onJoined?()
    }
    
    private func onPublishersAvailable(_ publishers: [JanusEventMessagePluginPublisher]) {
        for publisher in publishers where publisher.hasFeed {
            attachToPlugin { [weak self] message in
                self?.onSubscriberHandleCreationSuccess(message, publisher: publisher)
            }
        }
    }
    
    private func onLeavingFeed(withId feedId: Int) {
        // Get feed by id.
        guard let feed = feeds[feedId] else {
            logger.warning("Janus feed leaving handler: No feed found for id: \(feedId)")
            return
        }
        
        // Call feed leaving block.
        feed.onLeaving?()
    }
    
    private func onRemoteJSEP(message: JanusEventMessage) {
        // Get handle for sender.
        guard message.hasSender, let handle = handles[message.sender] else {
            logger.warning("Janus handle onRemoteJSEP but no handle found for id: \(message.sender) -- \(message)")
            return
        }
        
        // Call remote JSEP block.
        handle.onRemoteJSEP(message.jsep)
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
        
        // Create publisher handle.
        attachToPlugin { [weak self] message in
            self?.onPublisherHandleCreationSuccess(message)
        }
    }
    
    private func onPublisherHandleCreationSuccess(_ message: JanusTxResponseMessage) {
        // Get handle id from message data.
        guard message.hasDataId else {
            logger.error("Janus handle creation succeeded but id returned was empty...\(message)")
            return
        }
        
        // Get handle id from message.
        let handleId = message.dataId
        
        // Create new handle for publisher.
        let handle = createHandle(
            id: message.dataId,
            onRemoteJSEP: { [weak self] jsep in
                self?.delegate?.onPublisherRemoteJSEP(handleId: handleId, jsep: jsep)
            },
            onJoined: { [weak self] in
                self?.delegate?.onPublisherJoined(handleId: handleId)
            }
        )
        
        // Join room as publisher.
        joinRoom(as: .publisher, handle: handle)
    }
    
    private func onSubscriberHandleCreationSuccess(
        _ message: JanusTxResponseMessage,
        publisher: JanusEventMessagePluginPublisher
    ) {
        // Get handle id from message data.
        guard message.hasDataId else {
            logger.error("Janus handle creation succeeded but id returned was empty...\(message)")
            return
        }
        
        // Get handle id from message.
        let handleId = message.dataId
        
        // Get feed id from publisher.
        let feedId = publisher.feedId
        
        // Create new handle for subscriber.
        let handle = createHandle(
            id: message.dataId,
            onRemoteJSEP: { [weak self] jsep in
                self?.delegate?.onSubscriberRemoteJSEP(handleId: handleId, jsep: jsep)
            },
            feedId: feedId,
            onLeaving: { [weak self] in
                self?.onSubscriberLeaving(handleId: handleId, feedId: feedId)
            }
        )
        
        // Register handle as a feed.
        feeds[feedId] = handle
        
        // Join room as subscriber.
        joinRoom(as: .listener, handle: handle)
    }
    
    private func onSubscriberLeaving(handleId: Int, feedId: Int) {
        // Create new transaction to create a new handle.
        let tx = createTx(
            onSuccess: { [weak self] message in
                self?.onSubscriberLeavingSuccess(handleId: handleId, feedId: feedId)
            },
            onError: { [weak self] message in
                self?.onSubscriberLeavingError(message)
            }
        )
        
        // Send message to Janus.
        sendMessage(JanusLeaveMessage(
            sessionId: sessionId!,
            handleId: handleId,
            txId: tx.id
        ))
    }
    
    private func onSubscriberLeavingSuccess(handleId: Int, feedId: Int) {
        delegate?.onSubscriberLeaving(handleId: handleId)
        
        handles.removeValue(forKey: handleId)
        
        if feedId != 0 {
            feeds.removeValue(forKey: feedId)
        }
    }
    
    private func onJoinedRoomSuccess(as ptype: JanusJoinRoomMessageBody.PType) {
        logger.info("Successfully joined room as \(ptype.rawValue)")
    }
    
    private func joinRoom(as ptype: JanusJoinRoomMessageBody.PType, handle: JanusHandle) {
        // Create new transaction to join room.
        let tx = createTx(
            onSuccess: { [weak self] _ in
                self?.onJoinedRoomSuccess(as: ptype)
            },
            onError: { [weak self] message in
                self?.onJoinedRoomError(message)
            }
        )
        
        // Send message requesting to join room.
        sendMessage(JanusJoinRoomMessage(
            sessionId: sessionId!,
            handleId: handle.id,
            txId: tx.id,
            requestType: .join,
            room: roomId,
            ptype: ptype,
            feed: handle.feedId
        ))
    }
        
    private func attachToPlugin(then onSuccess: @escaping JanusTxBlock) {
        // Create new transaction to create a new handle.
        let tx = createTx(
            onSuccess: onSuccess,
            onError: { [weak self] message in
                self?.onHandleCreationError(message)
            }
        )
        
        // Send message to Janus.
        sendMessage(JanusAttachToPluginMessage(sessionId: sessionId!, txId: tx.id))
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
    
    private func createHandle(
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
    
    private func createTx(onSuccess: @escaping JanusTxBlock, onError: @escaping JanusTxBlock) -> JanusTx {
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
    
    private func serializeMessage(_ message: JanusMessage) -> String? {
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
    
    private func onJoinedRoomError(_ message: JanusTxResponseMessage) {
        logger.error("Janus failed to join room: code=\(message.error.code), reason=\(message.error.reason).")
    }
    
    private func onSubscriberLeavingError(_ message: JanusTxResponseMessage) {
        logger.error("Janus failed to leave as subscriber: code=\(message.error.code), reason=\(message.error.reason).")
    }
}
