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
    
    // Size and origin of workspace window -- equivalent to that of the Sidebar.
    static let size = SidebarWindow.size
    static let origin = SidebarWindow.origin
    
    // Right padding of workspace window as it pertains to its content.
    static let paddingRight: Float = 6
    
    // Style information of for group of member windows.
    enum MembersStyle {
        // X-position of the right edge of members.
        static let rightEdge = Float(WorkspaceWindow.origin.x + WorkspaceWindow.size.width) - WorkspaceWindow.paddingRight
        
        // Initial distance of members from top of screen.
        static let topOffset: Float = 240
        
        // Vertical spacing between members.
        static let gutterSpacing: Float = 10
    }
    
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
    
    func onMemberStateUpdate(forMemberId: String) {
        // Set previous state to current state for all adjacent member windows.
        for (memberId, memberWindow) in membersMap {
            if memberId == forMemberId {
                continue
            }
            
            memberWindow.registerStateUnchanged()
        }
        
        updateMemberSizesAndPositions()
    }
    
    // Create a new member window for a given member.
    private func createMemberWindow(forMember member: Member) {
        // Create member window.
        let memberWindow = MemberWindow(member: member, onStateUpdated: { [weak self] memberId in
            self?.onMemberStateUpdate(forMemberId: memberId)
        })

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
    
    // Set initial size and position of each member.
    private func setInitialMemberSizesAndPositions() {
        let memberWindows = getOrderedMemberWindows()
        var memberUpdates = [(MemberWindow, NSSize, NSPoint)]()
        var newSize: NSSize
        var newY: Float
        var newPosition: NSPoint
        
        // First calculate updates across all members.
        for (i, memberWindow) in memberWindows.enumerated() {
            // Calculate new size.
            newSize = memberWindow.calculateSize(forState: memberWindow.state)
            
            // Calculate new Y-position.
            newY = getInitialYPositionForMember(memberWindow: memberWindow, atIndex: i)

            // Calculate new position
            newPosition = NSPoint(x: CGFloat(MembersStyle.rightEdge) - newSize.width, y: CGFloat(newY))
            
            // Add updates to list.
            memberUpdates.append((memberWindow, newSize, newPosition))
        }
        
        // Apply all updates.
        for (memberWindow, size, position) in memberUpdates {
            memberWindow.render(size: size, position: position)
        }
    }
    
    // Update size and position of each member.
    private func updateMemberSizesAndPositions() {
        var memberUpdates = [(MemberWindow, NSSize, NSPoint)]()
        var memberWindow: MemberWindow
        var newSize: NSSize
        var newY: Float
        var newPosition: NSPoint

        // Get ordered list of existing member windows.
        let memberWindows = getOrderedMemberWindows()

        // Find the index of the first member window that should change size due to a state change (if any).
        guard let (firstIndexWithSizeChange, firstOffset) = findFirstMemberWithSizeChange(memberWindows) else {
            return
        }
                
        // Subtract firstOffset to all member windows above firstIndexWithSizeChange.
        for i in 0..<firstIndexWithSizeChange {
            memberWindow = memberWindows[i]
            
            // Add firstOffset to y-origin of member window.
            newY = Float(memberWindow.frame.origin.y) - firstOffset
            
            // Create new position.
            newPosition = NSPoint(x: memberWindow.frame.origin.x, y: CGFloat(newY))
            
            // Register update to apply later.
            memberUpdates.append((
                memberWindow,
                memberWindow.frame.size,
                NSPoint(x: memberWindow.frame.origin.x, y: CGFloat(newY))
            ))
        }
        
        var selfOffset: Float = 0
        var offsetDueToSizeChanges: Float = 0
        
        // Apply updates to remaining member windows (including the first one with a size change).
        for j in firstIndexWithSizeChange..<memberWindows.count {
            memberWindow = memberWindows[j]

            // Get the offset for this member window due to its own size change (if any).
            selfOffset = j == firstIndexWithSizeChange ? firstOffset : memberWindow.getVerticalOffsetForStateChange()
            
            if abs(selfOffset) > 0 {
                offsetDueToSizeChanges += selfOffset
                newSize = memberWindow.calculateSize(forState: memberWindow.state)
            } else {
                newSize = memberWindow.frame.size
            }

            // Add offsetDueToSizeChanges to y-origin of member window.
            newY = Float(memberWindow.frame.origin.y) + offsetDueToSizeChanges

            // Calculate new position
            newPosition = NSPoint(x: CGFloat(MembersStyle.rightEdge) - newSize.width, y: CGFloat(newY))
            
            // Add updates to list.
            memberUpdates.append((memberWindow, newSize, newPosition))
        }
        
        // Apply all updates.
        for (memberWindow, size, position) in memberUpdates {
            memberWindow.render(size: size, position: position)
        }
    }
    
    private func getInitialYPositionForMember(memberWindow: MemberWindow, atIndex index: Int) -> Float {
        let heightWithGutter = Float(memberWindow.getIdleWindowSize().height) + MembersStyle.gutterSpacing
        return Float(Screen.getHeight()) - MembersStyle.topOffset - (heightWithGutter * Float(index))
    }
    
    private func getOrderedMemberWindows() -> [MemberWindow] {
        var memberWindows = [MemberWindow]()
                
        for member in members {
            guard let memberWindow = membersMap[member.id] else {
                continue
            }
            
            memberWindows.append(memberWindow)
        }
        
        return memberWindows
    }
    
    private func findFirstMemberWithSizeChange(_ memberWindows: [MemberWindow]) -> (Int, Float)? {
        var offset: Float = 0
        
        for (i, memberWindow) in memberWindows.enumerated() {
            offset = memberWindow.getVerticalOffsetForStateChange()
                        
            if abs(offset) > 0 {
                return (i, offset)
            }
        }
        
        return nil
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
        setInitialMemberSizesAndPositions()
    
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
