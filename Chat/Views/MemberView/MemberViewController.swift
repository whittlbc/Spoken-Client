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

    // Proper initializer to use when rendering member.
    convenience init(member: Member) {
        self.init()
        self.member = member
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
        view = MemberView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // HACK -- remove in exchange for avatar view and other subviews
        view.wantsLayer = true
        view.layer?.backgroundColor = CGColor.white
    }
}
