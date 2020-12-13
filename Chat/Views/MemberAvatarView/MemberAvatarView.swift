//
//  MemberAvatarView.swift
//  Chat
//
//  Created by Ben Whittle on 12/12/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class MemberAvatarView: NSView {
    
    enum ShadowStyle {
        static let color = CGColor.black
        static let opacity: Float = 0.9
    }

    var avatar = ""

    // Proper initializer to use when rendering view.
    convenience init(avatar: String, frame: NSRect) {
        self.init(frame: frame)

        // Set avatar string.
        self.avatar = avatar

        // Start loading image
        
        // Render avatar
        self.render()
    }
    
    // Override delegated init.
    private override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addShadow() {
        shadow = NSShadow()
        
//      shadowOffset: CGSize(width: -5, height: -6),
//      shadowRadius: 4,
        layer?.shadowColor = ShadowStyle.color
        layer?.shadowOpacity = ShadowStyle.opacity
        
//        layer?.shadowPath = NSBezierPath(
//            roundedRect: NSRect(
//                x: frame.origin.x + 2,
//                y: frame.origin.y + 2,
//                width: frame.width - 4,
//                height: frame.height - 4
//            ),
//            xRadius: cornerRadius - 1,
//            yRadius: cornerRadius - 1
//        ).cgPath
    }
    
    private func renderImage() {
        let image = NSImage(byReferencing: NSURL(string: avatar)! as URL)

        let imageView = NSImageView(image: image)

        imageView.wantsLayer = true
        
        imageView.layer?.masksToBounds = true
        
//        imageView.layer?.cornerRadius = layer!.cornerRadius
        
        imageView.frame = bounds
                
        addSubview(imageView)
        
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//
//        NSLayoutConstraint.activate([
//            imageView.heightAnchor.constraint(
//                equalTo: heightAnchor
//            ),
//
//            imageView.widthAnchor.constraint(
//                equalTo: widthAnchor
//            ),
//
//            // Align central axes.
//            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
//            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
//        ])
    }
    
    private func render() {
        // Make view layer-based.
        wantsLayer = true

        // Round corners.
//        layer?.cornerRadius = self.accessibilityParent() ( bounds.width / 2 ) * 0.7
        
        // Add shadow.
//        addShadow()
        
        // Render image as subview.
        renderImage()
    }
    
//    required init(frame frameRect: NSRect, image: NSImage, shadowOffset: CGSize, shadowRadius: CGFloat,
//                  shadowColor: CGColor, shadowOpacity: Float) {
//        super.init(frame: frameRect)
//
//        self.wantsLayer = true
//
//        let cornerRadius = frame.width / 2
//        self.layer?.cornerRadius = cornerRadius
//
//        self.shadow = NSShadow()
//        self.layer?.shadowOffset = shadowOffset
//        self.layer?.shadowRadius = shadowRadius
//        self.layer?.shadowColor = shadowColor
//        self.layer?.shadowOpacity = shadowOpacity
//        self.layer?.shadowPath = NSBezierPath(
//            roundedRect: NSRect(
//                x: frame.origin.x + 2,
//                y: frame.origin.y + 2,
//                width: frame.width - 4,
//                height: frame.height - 4
//            ),
//            xRadius: cornerRadius - 1,
//            yRadius: cornerRadius - 1
//        ).cgPath
//
//        let imageView = NSImageView(image: image)
//
//        imageView.wantsLayer = true
//        imageView.layer?.masksToBounds = true
//        imageView.layer?.cornerRadius = cornerRadius
//
//        addSubview(imageView)
//
//        imageView.setFrameOrigin(NSPoint(x: 0, y: 0))
//        imageView.setFrameSize(frame.size)
//    }
}
