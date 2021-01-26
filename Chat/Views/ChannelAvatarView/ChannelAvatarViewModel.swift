//
//  ChannelAvatarViewModel.swift
//  Chat
//
//  Created by Ben Whittle on 1/23/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Combine

class ChannelAvatarViewModel {
    
    typealias ImageResult = Result<NSImage, Error>
    
    var channel: Channel
        
    var currentMember: Member { channel.members.first(where: { $0.userId == Session.currentUserId! })! }
    
    var recipientMember: Member { channel.members.first(where: { $0.userId != Session.currentUserId! })! }

    @Published private(set) var currentMemberAvatar: NSImage?
    
    @Published private(set) var recipientMemberAvatar: NSImage?
    
    private var videoPlaceholderAvatar: NSImage?

    private var currentMemberAvatarResult = ImageResult.success(NSImage()) {
        didSet {
            switch currentMemberAvatarResult {
            case .success(let image):
                self.currentMemberAvatar = image
            case .failure(_):
                self.currentMemberAvatar = nil
            }
        }
    }
    
    private var recipientMemberAvatarResult = ImageResult.success(NSImage()) {
        didSet {
            switch recipientMemberAvatarResult {
            case .success(let image):
                self.recipientMemberAvatar = image
            case .failure(_):
                self.recipientMemberAvatar = nil
            }
        }
    }
    
    private var currentMemberCancellable: AnyCancellable?

    private var recipientMemberCancellable: AnyCancellable?

    init(channel: Channel) {
        self.channel = channel
    }
    
    // Fetch avatar image for current member user.
    func loadCurrentMemberAvatar() {
        currentMemberCancellable = dataProvider.user
            .avatar(id: Session.currentUserId!)
            .asResult()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.currentMemberAvatarResult = result
            }
    }
    
    // Fetch avatar image for recipient member user.
    func loadRecipientMemberAvatar() {
        recipientMemberCancellable = dataProvider.user
            .avatar(id: recipientMember.userId)
            .asResult()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.recipientMemberAvatarResult = result
            }
    }
    
    func upsertVideoPlaceholderAvatar() {
        // If video placeholder exists in the image cache for the current user, store it here locally.
        if let videoPlaceholder = dataProvider.user.videoPlaceholder(id: Session.currentUserId!) {
            videoPlaceholderAvatar = videoPlaceholder
        }
        // Otherwise, ensure current user's avatar is available.
        else if currentMemberAvatar == nil {
            loadCurrentMemberAvatar()
        }
    }
    
    func getVideoPlaceholderAvatar() -> NSImage? {
        return videoPlaceholderAvatar ?? currentMemberAvatar
    }
}
