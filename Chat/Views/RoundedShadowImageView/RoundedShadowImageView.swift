//
//  TeamMemberView.swift
//  Chat
//
//  Created by Ben Whittle on 12/4/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class RoundedShadowImageView: NSView {

    required init(frame frameRect: NSRect, image: NSImage, shadowOffset: CGSize, shadowRadius: CGFloat,
                  shadowColor: CGColor, shadowOpacity: Float) {
        super.init(frame: frameRect)
        
        self.wantsLayer = true

        let cornerRadius = frame.width / 2
        self.layer?.cornerRadius = cornerRadius

        self.shadow = NSShadow()
        self.layer?.shadowOffset = shadowOffset
        self.layer?.shadowRadius = shadowRadius
        self.layer?.shadowColor = shadowColor
        self.layer?.shadowOpacity = shadowOpacity
        self.layer?.shadowPath = NSBezierPath(
            roundedRect: NSRect(
                x: frame.origin.x + 2,
                y: frame.origin.y + 2,
                width: frame.width - 4,
                height: frame.height - 4
            ),
            xRadius: cornerRadius - 1,
            yRadius: cornerRadius - 1
        ).cgPath
        
        
        let imageView = NSImageView(image: image)

        imageView.wantsLayer = true
        imageView.layer?.masksToBounds = true
        imageView.layer?.cornerRadius = cornerRadius

        addSubview(imageView)

        imageView.setFrameOrigin(NSPoint(x: 0, y: 0))
        imageView.setFrameSize(frame.size)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
