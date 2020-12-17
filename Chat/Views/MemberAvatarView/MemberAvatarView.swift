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
    
    // Style of avatar view relative to parent member view.
    enum RelativeStyle {
        // Height of avatar relative to parent member view.
        static let relativeHeight: CGFloat = 0.7
        
        // Absolute left shift of avatar view relative to parent member view.
        static let leftOffset: CGFloat = -5.0
    }
    
    // URL string to avatar.
    var avatar = ""
    
    // Container view of avatar.
    private var containerView = RoundShadowView()
    
    // View with image content.
    private var imageView = RoundView()
    
    // Create new container view.
    private func createContainerView() {
        // Create new round view with with drop shadow.
        containerView = RoundShadowView()

        // Make it layer based and allow for overflow so that shadow can be seen.
        containerView.wantsLayer = true
        containerView.layer?.masksToBounds = false
                
        // Add container view to self.
        addSubview(containerView)
    }
    
    // Set up container view auto-layout.
    private func constrainContainerView() {
        // Set up auto-layout for sizing/positioning.
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Add auto-layout constraints.
        NSLayoutConstraint.activate([
            // Set height of container to 70% of self height.
            containerView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: RelativeStyle.relativeHeight),
            
            // Keep container height and width the same.
            containerView.widthAnchor.constraint(equalTo: containerView.heightAnchor),
            
            // Align right sides (but shift it left the specified amount).
            containerView.rightAnchor.constraint(equalTo: rightAnchor, constant: RelativeStyle.leftOffset),
            
            // Align horizontal axes.
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

    }
    
    // Create new image view.
    private func createImageView() {
        // Create new round view.
        imageView = RoundView()
                
        // Make it layer based and ensure overflow is hidden.
        imageView.wantsLayer = true
        imageView.layer?.masksToBounds = true

        // Add image to container.
        containerView.addSubview(imageView)
    }
    
    // Set up image view auto-layout.
    private func constrainImageView() {
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

    // Render container view.
    private func renderContainerView() {
        // Create container view.
        createContainerView()
        
        // Constrain container view.
        constrainContainerView()
    }
    
    // Render image view.
    private func renderImageView() {
        // Create image view.
        createImageView()
        
        // Constrain image view.
        constrainImageView()
    }
    
    func render() {
        // Render avatar container.
        renderContainerView()
        
        // Render avatar image.
        renderImageView()
    }
}
