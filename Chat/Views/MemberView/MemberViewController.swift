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
    
    // Initial member view frame -- provided from window.
    var initialFrame = NSRect()
    
    // Avatar subview.
    var avatarView = MemberAvatarView()
    
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
        
        // Add avatar view as subview.
        addAvatarView()
    }
    
    func addAvatarView() {
        // Create new avatar view.
        avatarView = MemberAvatarView()
        
        // Assign avatar URL string.
        avatarView.avatar = member.user.avatar
                        
        // Add it as a subview.
        view.addSubview(avatarView)

        // Set up auto-layout for sizing/positioning.
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        // Add auto-layout constraints.
        NSLayoutConstraint.activate([
            avatarView.heightAnchor.constraint(equalToConstant: 32.0),
            
            avatarView.widthAnchor.constraint(equalToConstant: 32.0),

            // Align right sides.
            avatarView.rightAnchor.constraint(equalTo: view.rightAnchor),

            // Align horizontal axes.
            avatarView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
//
//        // Render avatar view, adding its own subviews.
        avatarView.render()
    }
}
