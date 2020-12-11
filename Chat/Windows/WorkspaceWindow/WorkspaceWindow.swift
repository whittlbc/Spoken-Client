//
//  WorkspaceWindow.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Cocoa

// Workspace window state.
enum WorkspaceState {
    case loading
    case loaded(Workspace?)
    case failed(Error)
}

// Window housing all sidebar app functionality as it relates to a given workspace.
class WorkspaceWindow: FloatingWindow {
    
    // Let size and origin of window be equivalent to that of the Sidebar.
    static let size = SidebarWindow.size
    static let origin = SidebarWindow.origin
    
    // Right padding of workspace window as it pertains to its content.
    static let paddingRight = 6
    
    // X position of the right-most any content inside this window can be.
    static let contentRight = Int(WorkspaceWindow.origin.x) + Int(WorkspaceWindow.size.width) - WorkspaceWindow.paddingRight
    
    // Controller for all actions that can be performed in this window.
    private let logicController = WorkspaceLogicController()
    
    // Dictionary mapping a member's id to its respective window.
    private var membersMap = [String:MemberWindow]()
    
    // Ordered list of members.
    private var members = [Member]()
    
    // Override delegated init, size/position window on screen, and fetch workspaces.
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)

        // Position and size window on screen.
        repositionWindow(to: SidebarWindow.origin)
        resizeWindow(to: SidebarWindow.size)
    }

    // Load current workspace with all its members.
    func loadCurrentWorkspace() {
        // Render loading view.
        render(.loading)
                
        logicController.load { [weak self] state in
            self?.render(state)
        }
    }
    
    // Create a new member window for a given member.
    private func createMemberWindow(forMember member: Member) {
        // Create member window.
        let memberWindow = MemberWindow(member: member)

        // Create member view controller and attach to window.
        let memberController = MemberViewController(member: member)
        memberWindow.contentViewController = memberController

        // Bind member window events to controller.
        memberWindow.bind(.title, to: memberController, withKeyPath: "title", options: nil)

        // Make each member view the first responder inside the window.
        memberWindow.makeFirstResponder(memberController.view)

        // Add window to members map.
        membersMap[member.id] = memberWindow
    }
    
    // Add all member windows as child windows.
    private func addMemberWindows() {
        for member in members {
            if let memberWindow = membersMap[member.id] {
                addChildWindow(memberWindow, ordered: NSWindow.OrderingMode.above)
            }
        }
    }
    
    // Update size and position of each member
    private func sizeAndPositionMembers() {
        var memberUpdates = [(MemberWindow, NSSize, NSPoint)]()
        var newSize: NSSize
        var newPosition: NSPoint
        
        // First calculate updates across all members.
        for (i, member) in members.enumerated() {
            // Ensure window actually exists.
            guard let memberWindow = membersMap[member.id] else {
                continue
            }
            
            // Calculate new size.
            newSize = memberWindow.calculateSize()
            
            // Calculate new position.
            newPosition = NSPoint(
                x: WorkspaceWindow.contentRight - Int(newSize.width),
                y: 300 + (i * TeamMemberView.height) + (i * 10)
            )
            
            // Add updates to list.
            memberUpdates.append((memberWindow, newSize, newPosition))
        }
        
        // Apply all updates.
        for (memberWindow, size, position) in memberUpdates {
            memberWindow.render(size: size, position: position)
        }
    }
    
    // Loading view
    private func renderLoading() {
        // TODO
    }
    
    // Error view
    private func renderError(_ error: Error) {
        // TODO
    }
    
    // Render workspace if exists; Otherwise, show the view to create a new workspace.
    private func renderLoaded(_ workspace: Workspace?) {
        if let ws = workspace {
            renderWorkspace(ws)
        } else {
            renderCreateFirstWorkspace()
        }
    }
    
    // Create new workspace view
    private func renderCreateFirstWorkspace() {
        // TODO
    }
    
    // Current workspace view
    private func renderWorkspace(_ workspace: Workspace) {
        // Update members list.
        members = workspace.members
        
        // Render all members of workspace.
        renderMembers()
    }
    
    // Render all workspace members on screen in separate windows.
    private func renderMembers() {
        // Clear out members map.
        membersMap.removeAll()
        
        // Create each member window and add them to the membersMap.
        for member in members {
            createMemberWindow(forMember: member)
        }
        
        // Size and position member windows.
        sizeAndPositionMembers()
    
        // Add all member windows as child windows.
        addMemberWindows()
    }
    
    // Render workspace window contents based on current state.
    private func render(_ state: WorkspaceState) {
        switch state {
        // Loading view
        case .loading:
            renderLoading()
            
        // Loaded view
        case .loaded(let workspace):
            renderLoaded(workspace)
        
        // Error view
        case .failed(let error):
            renderError(error)
        }
    }
}
