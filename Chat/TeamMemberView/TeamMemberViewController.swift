//
//  TeamMemberViewController.swift
//  Chat
//
//  Created by Ben Whittle on 12/4/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

class TeamMemberViewController: NSViewController {
    
    public var teamMember:NSDictionary = [:]
    
    override func loadView() {
        view = TeamMemberView(
            frame: NSRect(x: 0, y: 0, width: TeamMemberView.width, height: TeamMemberView.height),
            teamMember: self.teamMember
        )
    }
}
