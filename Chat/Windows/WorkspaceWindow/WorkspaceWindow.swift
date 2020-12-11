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
    
    // Controller for all actions that can be performed in this window.
    private let logicController = WorkspaceLogicController()
    
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
        // Render all members of workspace.
        renderMembers(workspace.members)
    }
    
    // Render all workspace members on screen in separate windows.
    private func renderMembers(_ members: [Member]) {
        print("Number of members: \(members.count)")
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
