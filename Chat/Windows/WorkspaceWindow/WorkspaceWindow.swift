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
    
    // Size of workspace window -- same as Sidebar.
    static let size = SidebarWindow.size
    
    // Origin of workspace window -- same as Sidebar.
    static let origin = SidebarWindow.origin
    
    // Right padding of workspace window as it pertains to its content.
    static let paddingRight: Float = 6
    
    // Style information for group of member windows.
    enum MembersStyle {
        // X-position of the right edge of members.
        static let rightEdge = Float(WorkspaceWindow.origin.x + WorkspaceWindow.size.width) - WorkspaceWindow.paddingRight
        
        // Distance between top of workspace window and top-most member window.
        static let topOffset: Float = 240
        
        // Vertical spacing between members.
        static let gutterSpacing: Float = 0
    }
    
    // Animation configuration for all child windows that this workspace window controls.
    enum AnimationConfig {
        
        // Configuration for member window animations.
        enum MemberWindows {
            // Time it takes for a member window to update size and position during a state change.
            static let duration = 0.13
            
            // Name of timing function to use for all member window animations.
            static let timingFunctionName = CAMediaTimingFunctionName.easeOut
        }
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

        // Load current workspace and render the returned state.
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
        var specs = [(MemberWindow, NSSize, NSPoint)]()
        var size: NSSize
        var position: NSPoint
        
        // First calculate updates across all members.
        for (i, memberWindow) in getOrderedMemberWindows().enumerated() {
            // Calculate member size.
            size = memberWindow.getSizeForCurrentState()
            
            // Calculate member position.
            position = NSPoint(
                x: getMemberXPosition(forMemberSize: size),
                y: getInitialMemberYPosition(memberWindow: memberWindow, atIndex: i)
            )
            
            // Add updates to list.
            specs.append((memberWindow, size, position))
        }
        
        // Apply all updates.
        for (memberWindow, size, position) in specs {
            memberWindow.render(size: size, position: position)
        }
    }
    
    // Get x-position of member window for its given size.
    private func getMemberXPosition(forMemberSize size: NSSize) -> CGFloat {
        CGFloat(MembersStyle.rightEdge) - size.width
    }
    
    // Get the initial y-position of the member window at the provided index.
    private func getInitialMemberYPosition(memberWindow: MemberWindow, atIndex index: Int) -> CGFloat {
        // Get the idle member window height + any configured gutter spacing between members.
        let heightWithGutter = Float(memberWindow.getIdleWindowSize().height) + MembersStyle.gutterSpacing
        
        // Calculate the absolute position of this members window.
        return CGFloat(Float(Screen.getHeight()) - MembersStyle.topOffset - (heightWithGutter * Float(index)))
    }

    // Update size and position of each member.
    private func updateMemberSizesAndPositions(activeMemberId: String) {
        // Check if the latest state update will cause the active member window's size to change.
        let (sizeWillChange, activeWindow, activeHeightOffset, _) = getActiveMemberSizeChange(activeMemberId: activeMemberId)
        
        // Only continue if active member window will change size.
        if !sizeWillChange {
            return
        }
        
        // Unwrap active member window and height offset.
        let activeMemberWindow = activeWindow!
        let activeMemberHeightOffset = activeHeightOffset!

        // Get ordered list of existing member windows.
        let memberWindows = getOrderedMemberWindows()
        
        // Find the index of the active member window.
        let activeIndex = memberWindows.firstIndex{ $0 === activeMemberWindow }
        let activeMemberIndex = activeIndex!
        
        // Calculate new size and position destinations for all member windows.
        calculateMemberWindowDestinations(
            memberWindows: memberWindows,
            activeMemberIndex: activeMemberIndex,
            activeMemberHeightOffset: activeMemberHeightOffset
        )
        
        // Animate each member window to its new destination.
        animateMemberWindowsToDestinations(memberWindows)
        
        // If active member's new state is previewing, ensure it is the only member window in a previewing state.
        if activeMemberWindow.state == .previewing {
            ensureOnlyOneMemberIsPreviewing(memberWindows: memberWindows, activeMemberIndex: activeMemberIndex)
            
            // Add a timer to check the mouse position in relation to the active member window, and force
            // it out of the previewing state if the mouse isn't inside of the active member window anymore.
            activeMemberWindow.startPreviewingTimer()
        }
    }
        
    // Determine how much (if any) the active member window will change due to its latest state change.
    private func getActiveMemberSizeChange(activeMemberId: String) -> (Bool, MemberWindow?, Float?, Float?) {
        // Get active member window (the window that triggered the update).
        guard let activeMemberWindow = membersMap[activeMemberId] else {
            logger.error("Unable to find active window that triggered size update...")
            return (false, nil, nil, nil)
        }
        
        // Get the size offsets due to the active member window's size change.
        let (activeMemberHeightOffset, activeMemberWidthOffset) = activeMemberWindow.getStateChangeSizeOffset()
        
        // Don't do anything if no size change will take place.
        guard abs(activeMemberHeightOffset) > 0 || abs(activeMemberWidthOffset) > 0 else {
            logger.warning("No active window size change occurred...")
            return (false, nil, nil, nil)
        }
        
        return (true, activeMemberWindow, activeMemberHeightOffset, activeMemberWidthOffset)
    }

    // Get an array of member windows, top-to-bottom.
    private func getOrderedMemberWindows() -> [MemberWindow] {
        var memberWindows = [MemberWindow]()
                
        // Create an array of all workspace members with existing windows, top-to-bottom.
        for member in members {
            guard let memberWindow = membersMap[member.id] else {
                continue
            }
            
            memberWindows.append(memberWindow)
        }
        
        return memberWindows
    }
    
    // Calculate new animation destinations for each member window.
    private func calculateMemberWindowDestinations(memberWindows: [MemberWindow], activeMemberIndex: Int, activeMemberHeightOffset: Float) {
        var memberWindow: MemberWindow
        var newSize: NSSize
        var newPosition: NSPoint
        var destination: NSPoint
        
        // Calculate new size and position of all member windows.
        for i in 0..<memberWindows.count {
            memberWindow = memberWindows[i]
            
            // Get current animation destination of member.
            destination = memberWindow.getDestination()
            
            // Get size of member window for its current state.
            newSize = memberWindow.getSizeForCurrentState()
            
            // Calculate new member window position.
            newPosition = NSPoint(
                x: getMemberXPosition(forMemberSize: newSize),
                y: CGFloat(Float(destination.y) + (i < activeMemberIndex ? -activeMemberHeightOffset : activeMemberHeightOffset))
            )
            
            // Set newly calculated destination on member window, itself.
            memberWindow.setDestination(newPosition)
        }
    }

    // Animate each member window to its stored destination.
    private func animateMemberWindowsToDestinations(_ memberWindows: [MemberWindow]) {
        NSAnimationContext.runAnimationGroup({ context in
            // Configure animation attributes.
            context.duration = AnimationConfig.MemberWindows.duration
            context.timingFunction = CAMediaTimingFunction(name: AnimationConfig.MemberWindows.timingFunctionName)
            context.allowsImplicitAnimation = true

            // Vars for loop below.
            var newSize: NSSize
            var newPosition: NSPoint
            var newFrame: NSRect
            
            for memberWindow in memberWindows {
                // Get size and position to update the member window to.
                newSize = memberWindow.getSizeForCurrentState()
                newPosition = memberWindow.getDestination()
                
                // Create a new frame from the desired size and position.
                newFrame = NSRect(x: newPosition.x, y: newPosition.y, width: newSize.width, height: newSize.height)
                
                // Animate the member window to its new frame.
                memberWindow.animator().setFrame(newFrame, display: true)
                
                // Update the member window's content view to the latest state.
                memberWindow.updateViewState()
            }
        })
    }
    
    // Force a "mouse-exited" event on any previewing member windows that aren't the active member window.
    private func ensureOnlyOneMemberIsPreviewing(memberWindows: [MemberWindow], activeMemberIndex: Int) {
        for (i, memberWindow) in memberWindows.enumerated() {
            if i == activeMemberIndex {
                continue
            }
            
            // If a member that isn't the active member is found to be in
            // the previewing state, force it out of this state.
            if memberWindow.state == .previewing {
                memberWindow.registerMouseExited()
            }
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
        setInitialMemberSizesAndPositions()

        // Add all member windows as child windows.
        addMemberWindows()
    }
    
    // Render workspace window contents based on current state.
    func render(_ state: WorkspaceState) {
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
