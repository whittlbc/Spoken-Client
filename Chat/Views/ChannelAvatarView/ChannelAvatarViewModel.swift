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
    
    private var channel: Channel
    
    private var recipient: Member { channel.members.first(where: { $0.userId != Session.currentUserId! })! }

    @Published private(set) var image: NSImage?
    
    private var imageResult = ImageResult.success(NSImage()) {
        didSet {
            switch imageResult {
            case .success(let image):
                self.image = image
            case .failure(_):
                self.image = nil
            }
        }
    }

    private var cancellable: AnyCancellable?

    init(channel: Channel) {
        self.channel = channel
    }
    
    // Fetch avatar image for recipient user.
    func loadImage() {
        cancellable = dataProvider.user
            .avatar(id: recipient.userId)
            .asResult()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.imageResult = result
            }
    }
}
