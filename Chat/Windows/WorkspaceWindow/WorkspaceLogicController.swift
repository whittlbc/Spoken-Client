//
//  WorkspaceLogicController.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation
import Combine

// Used by workspace window to offload all networking logic.
class WorkspaceLogicController {

    // Type of closure required as a callback by the instance methods below.
    typealias Handler = (WorkspaceState) -> Void
    
    // The current workspace displayed in workspace window.
    var currentWorkspace: Workspace?
    
    // Array of API requests in case any need to be cancelled.
    private var requests = [AnyCancellable]()
    
    // Load current workspace with all of its channels.
    func load(then handler: @escaping Handler) {
        // Get current workspace -- either its already been set or pull it from cache.
        currentWorkspace = currentWorkspace ?? Workspace.current
        
        // If current workspace alredy exists, refetch its channels. Otherwise, fetch user workspaces first.
        currentWorkspace == nil ? fetchUserWorkspaces(then: handler) : fetchWorkspaceChannels(then: handler)
    }
    
    // Fetch all workspaces for the current user.
    private func fetchUserWorkspaces(then handler: @escaping Handler) {
        let currentUser = User.current!
        
        // Fetch current user's workspaces and handle networking response.
        currentUser.fetchWorkspaces().sink(receiveCompletion: { status in
            switch status {
            case .failure(let error):
                handler(.failed(error))
            default:
                break
            }
        }) { (response: [Workspace]) in
            // If no workspaces exist, load successfully but with nil workspace in state.
            if (response.isEmpty) {
                handler(.loaded(nil))
                return
            }
                        
            // Store workspace ids in cache.
            let workspaceIds = response.map(\.id)
            Cache.Ids.setWorkspaces(ids: workspaceIds)
            
            // Take the first workspace as the current one and cache it.
            self.currentWorkspace = response[0]
            Cache.Workspaces.setCurrent(self.currentWorkspace!)
            
            // Fetch channels now that current workspace has been determined.
            self.fetchWorkspaceChannels(then: handler)
            
        }.store(in: &requests)
    }
    
    // Fetch all channels for the current workspace.
    private func fetchWorkspaceChannels(then handler: @escaping Handler) {
//        // Fetch current workspace's channels and handle networking response.
//        currentWorkspace!.fetchChannels().sink(receiveCompletion: { status in
//            switch status {
//            case .failure(let error):
//                handler(.failed(error))
//            default:
//                break
//            }
//        }) { (response: [Channel]) in
//            // Set channels on current workspace.
//            self.currentWorkspace!.channels = response
//
//            // Tell workspace window that all has been loaded.
//            handler(.loaded(self.currentWorkspace))
//
//        }.store(in: &requests)
        
        // ----- Mock logic below ------
        
        // Set channels on current workspace.
        self.currentWorkspace!.channels = Mocks.Channels.all

        // Tell workspace window that all has been loaded.
        handler(.loaded(self.currentWorkspace))
    }
}
