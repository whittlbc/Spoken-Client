//
//  Socket.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Starscream
import Arrow

class Socket: WebSocketDelegate {
    
    var isConnected: Bool = false
    
    var webSocket: WebSocket!
    
    private let url: String
        
    private let headers: [String: String]
    
    private let requestTimeoutInterval: TimeInterval
    
    init(url: String, headers: [String: String] = [:], requestTimeoutInterval: TimeInterval = 5) {
        self.url = url
        self.headers = headers
        self.requestTimeoutInterval = requestTimeoutInterval
        self.webSocket = self.createWebSocket()
        self.webSocket.delegate = self
    }
    
    deinit {
        disconnect()
    }
    
    func connect() {
        webSocket.connect()
    }
    
    func disconnect() {
        webSocket.disconnect()
    }
    
    private func createWebSocket() -> WebSocket {
        WebSocket(request: self.buildInitialRequest(), certPinner: nil)
    }
    
    private func buildInitialRequest() -> URLRequest {
        // Create new url request.
        var request = URLRequest(url: self.buildURL())
        
        // Set timeout interval from instance property.
        request.timeoutInterval = self.requestTimeoutInterval
        
        // Apply headers to request.
        for (name, value) in self.headers {
            request.setValue(value, forHTTPHeaderField: name)
        }

        return request
    }
    
    private func buildURL() -> URL {
        guard let url = URL(string: self.url) else {
            fatalError("Socket url string is not a valid url -- \(self.url)")
        }
        
        return url
    }
    
    // WebSocketDelegate function to handle all socket events.
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        
        case .connected(let headers):
            logger.info("Socket connected")
            isConnected = true
            self.onConnected(headers: headers)

        case .disconnected(let reason, let code):
            logger.info("Socket disconnected")
            isConnected = false
            self.onDisconnected(reason: reason, code: code)
            
        case .text(let string):
            self.onMessage(string: string)
            
        case .binary(let data):
            self.onBinary(data: data)
            
        case .ping(let data):
            self.onPing(data: data)
            
        case .pong(let data):
            self.onPong(data: data)
            
        case .viabilityChanged(let value):
            self.onViabilityChanged(value: value)
            
        case .reconnectSuggested(let value):
            self.onReconnectSuggested(value: value)
        
        case .cancelled:
            logger.info("Socket cancelled and now disconnected")
            isConnected = false
            self.onCancelled()
            
        case .error(let error):
            isConnected = false
            
            if let err = error as? WSError {
                logger.error("Websocket error: \(err.message)")
            } else {
                logger.error("Socket encountered error and is now disconnected: \(error?.describe() ?? "")")
            }

            self.onError(error)
        }
    }
    
    func onConnected(headers: [String: String]) {}
    
    func onDisconnected(reason: String, code: UInt16) {}
    
    func onMessage(string: String) {}
    
    func onBinary(data: Data) {}
    
    func onPing(data: Data?) {}
    
    func onPong(data: Data?) {}
    
    func onViabilityChanged(value: Bool) {}
    
    func onReconnectSuggested(value: Bool) {}
    
    func onCancelled() {}
    
    func onError(_ error: Error?) {}
}
