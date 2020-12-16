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
        static let gutterSpacing: Float = 0
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
    
    // Handle individual member window state updates as a group.
    func onMemberStateUpdate(activeMemberId: String) {
        // Promote previous state to current state for all adjacent member windows.
        for (memberId, memberWindow) in membersMap {
            if memberId != activeMemberId {
                memberWindow.promotePreviousState()
            }
        }
        
        // Animate all member windows to new sizes/positions based on state change.
        updateMemberSizesAndPositions(activeMemberId: activeMemberId)
    }
        
    // Create a new member window for a given member.
    private func createMemberWindow(forMember member: Member) {
        // Create member window.
        let memberWindow = MemberWindow(member: member, onStateUpdated: { [weak self] memberId in
            self?.onMemberStateUpdate(activeMemberId: memberId)
        })

        // Get initial member window size.
        let initialSize = memberWindow.getSizeForCurrentState()
        
        // Create member view controller and attach to window.
        let memberController = MemberViewController(
            member: member,
            initialFrame: NSRect(x: 0, y: 0, width: initialSize.width, height: initialSize.height)
        )
        
        // Set MemberViewController as primary content view controller for member window.
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
    private func updateMemberSizesAndPositions(activeMemberId: String) {
        // Get active member window (the window that triggered the update).
        guard let activeMemberWindow = membersMap[activeMemberId] else {
            logger.error("Unable to find active window that triggered size update...")
            return
        }
        
        // Get the size offsets due to the active member window's size change.
        let (activeMemberHeightOffset, activeMemberWidthOffset) = activeMemberWindow.getStateChangeSizeOffset()
        
        // Don't do anything if no size change should take place.
        guard abs(activeMemberHeightOffset) > 0 || abs(activeMemberWidthOffset) > 0 else {
            return
        }
        
        // Get ordered list of existing member windows.
        let memberWindows = getOrderedMemberWindows()
        
        // Find the index of the active member window.
        let activeIndex = memberWindows.firstIndex{ $0 === activeMemberWindow }
        let activeMemberIndex = activeIndex!
        
        // Create array to store the new size and position of all adjacent member windows.
        var memberWindow: MemberWindow
        var newY: CGFloat
        var newSize: NSSize
        var newPosition: NSPoint
        var destination: NSPoint

        // Apply active member offset to all adjacent windows.
        for i in 0..<memberWindows.count {
            memberWindow = memberWindows[i]
            destination = memberWindow.getDestination()
            
            if i < activeMemberIndex {
                newY = CGFloat(Float(destination.y) - activeMemberHeightOffset)
            } else {
                newY = CGFloat(Float(destination.y) + activeMemberHeightOffset)
            }
            
            newSize = memberWindow.getSizeForCurrentState()
                        
            newPosition = NSPoint(
                x: CGFloat(MembersStyle.rightEdge) - newSize.width,
                y: newY
            )
            
            // Set member destination origin.
            memberWindow.setDestination(newPosition)
        }
        
        // Animate active member view and adjacent member windows.
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.13
            context.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)

            var size: NSSize
            var position: NSPoint
            
            for memberWindow in memberWindows {
                size = memberWindow.getSizeForCurrentState()
                position = memberWindow.getDestination()
                
                memberWindow.animator().setFrame(
                    NSRect(x: position.x, y: position.y, width: size.width, height: size.height),
                    display: true
                )
                
                memberWindow.updateViewState()
            }
        })

        let activeIsPreviewing = activeMemberWindow.state == .previewing
        
        for (i, memWin) in memberWindows.enumerated() {
            if i == activeMemberIndex {
                continue
            }
            
            if activeIsPreviewing && memWin.state == .previewing {
                memWin.forceMouseExit()
            }
        }
        
        if activeIsPreviewing {
            activeMemberWindow.startPreviewingTimer()
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
