//
//  MemberAvatarView.swift
//  Chat
//
//  Created by Ben Whittle on 12/12/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// View representing a workspace member's avatar.
class MemberAvatarView: NSView {
    
    // URL string to avatar.
    var avatar = ""
    
    // Container view of avatar.
    var containerView = RoundShadowView()
    
    // View with image content.
    var imageView = RoundView()

    // Render container view.
    private func renderContainerView() {
        // Create new round view with with drop shadow.
        containerView = RoundShadowView()

        // Make it layer based and allow for overflow so that shadow can be seen.
        containerView.wantsLayer = true
        containerView.layer?.masksToBounds = false
                
        // Add container view to self.
        addSubview(containerView)
        
        // Set up auto-layout for sizing/positioning.
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Add auto-layout constraints.
        NSLayoutConstraint.activate([
            // Set height of container to 70% of self height.
            containerView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.7),
            
            // Keep container height and width the same.
            containerView.widthAnchor.constraint(equalTo: containerView.heightAnchor),
            
            // Align right sides (but shift it left 5px).
            containerView.rightAnchor.constraint(equalTo: rightAnchor, constant: -5.0),
            
            // Align horizontal axes.
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    // Render image view.
    private func renderImageView() {
        // Create new round view.
        let imageView = RoundView()
                
        // Make it layer based and ensure overflow is hidden.
        imageView.wantsLayer = true
        imageView.layer?.masksToBounds = true

        // Add image to container.
        containerView.addSubview(imageView)
        
        // Set up auto-layout for sizing/positioning.
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Fix image size to container size (equal height, width, and center).
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: containerView.heightAnchor),
            imageView.widthAnchor.constraint(equalTo: containerView.heightAnchor),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])

        // Create image from avatar URL.
        let image = NSImage(byReferencing: URL(string: avatar)!)

        // Set image to contents of view.
        imageView.layer?.contents = image
        
        // Constrain the image's size to the view's size.
        imageView.layer?.contentsGravity = .resizeAspectFill
    }
    
    func render() {
        renderContainerView()
        renderImageView()
    }
}
