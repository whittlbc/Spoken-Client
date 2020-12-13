//
//  MemberViewController.swift
//  Chat
//
//  Created by Ben Whittle on 12/11/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class MemberViewController: NSViewController {

    // Workspace member associated with this view.
    var member = Member()
    
    var initialFrame = NSRect()
    
    // Proper initializer to use when rendering member.
    convenience init(member: Member, initialFrame: NSRect) {
        self.init()
        self.member = member
        self.initialFrame = initialFrame
    }
    
    // Override delegated init.
    private override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Use MemberView as view.
    override func loadView() {
        view = MemberView(frame: initialFrame)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let avatarContainerView = NSView()
        
        view.addSubview(avatarContainerView)
        
        avatarContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            avatarContainerView.heightAnchor.constraint(
                equalTo: view.heightAnchor
            ),
            
            avatarContainerView.widthAnchor.constraint(
                equalTo: avatarContainerView.heightAnchor
            ),

            // Constrain right sides together.
            avatarContainerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            
            // Align horizontal axes.
            avatarContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        let avatarView = RoundShadowView()
                
        avatarView.wantsLayer = true
        avatarView.layer?.masksToBounds = false
                
        avatarContainerView.addSubview(avatarView)
        
        avatarView.translatesAutoresizingMaskIntoConstraints = false
                                
        NSLayoutConstraint.activate([
            avatarView.heightAnchor.constraint(
                equalTo: avatarContainerView.heightAnchor,
                multiplier: 0.7
            ),
            
            avatarView.widthAnchor.constraint(
                equalTo: avatarView.heightAnchor
            ),

            avatarView.rightAnchor.constraint(equalTo: avatarContainerView.rightAnchor, constant: -5.0),
            avatarView.centerYAnchor.constraint(equalTo: avatarContainerView.centerYAnchor),
        ])
        
        let avatarImageView = RoundView()
                
        avatarImageView.wantsLayer = true
        
        avatarImageView.layer?.masksToBounds = true
                
        avatarView.addSubview(avatarImageView)
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
                                
        NSLayoutConstraint.activate([
            avatarImageView.heightAnchor.constraint(
                equalTo: avatarView.heightAnchor
            ),
            
            avatarImageView.widthAnchor.constraint(
                equalTo: avatarView.heightAnchor
            ),

            avatarImageView.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
        ])

        
        let image = NSImage(byReferencing: URL(string: member.user.avatar)!)

        avatarImageView.layer?.contents = image
        avatarImageView.layer?.contentsGravity = .resizeAspectFill
    }
}
