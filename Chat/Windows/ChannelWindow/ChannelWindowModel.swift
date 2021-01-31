//
//  ChannelWindowModel.swift
//  Chat
//
//  Created by Ben Whittle on 1/30/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//
import Cocoa
import Combine

class ChannelWindowModel {
    
    typealias MessageResult = Result<Message, Error>
    
    var channel: Channel
    
    @Published private(set) var currentMessage: Message?

    private var currentMessageResult = MessageResult.success(Message()) {
        didSet {
            // If timer has already expired, set current messsage from result.
            if networkTimer == nil {
                setCurrentMessageFromResult()
            }
        }
    }
    
    private var currentMessageRequestCompleted = false
    
    private var networkTimer: Timer?
    
    private var currentMessageCancellable: AnyCancellable?
    
    init(channel: Channel) {
        self.channel = channel
    }
    
    func createRecordingMessage(fileSize: Int) {
        currentMessageRequestCompleted = false
    
        startNetworkTimer()
        
        currentMessageCancellable = dataProvider.message
            .create(
                channelId: channel.id,
                messageType: UserSettings.Video.useCamera ? .video : .audio
            )
            .asResult()
            .sink { [weak self] result in
                self?.currentMessageRequestCompleted = true
                self?.currentMessageResult = result
            }
    }
    
    private func setCurrentMessageFromResult() {
        switch currentMessageResult {
        case .success(let message):
            self.currentMessage = message
        case .failure(_):
            self.currentMessage = nil
        }
    }
    
    private func startNetworkTimer() {
        if networkTimer != nil {
            return
        }
        
        networkTimer = Timer.scheduledTimer(
            timeInterval: TimeInterval(ChannelWindow.ArtificialTiming.showRecordingSendingDuration),
            target: self,
            selector: #selector(onNetworkTimerEnd),
            userInfo: nil,
            repeats: false
        )
    }
    
    @objc private func onNetworkTimerEnd() {
        cancelNetworkTimer()
        
        // If request has already completed, set current message from result.
        if currentMessageRequestCompleted {
            setCurrentMessageFromResult()
        }
    }
    
    private func cancelNetworkTimer() {
        if networkTimer == nil {
            return
        }
        
        networkTimer!.invalidate()
        networkTimer = nil
    }
}
