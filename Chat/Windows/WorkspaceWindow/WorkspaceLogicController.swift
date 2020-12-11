//
//  WorkspaceLogicController.swift
//  Chat
//
//  Created by Ben Whittle on 12/10/20.
//  Copyright © 2020 Ben Whittle. All rights reserved.
//

import Foundation
import Combine

class WorkspaceLogicController {

    typealias Handler = (WorkspaceState) -> Void
    
    // Current workspace displayed in workspace window.
    var currentWorkspace: Workspace?
    
    // Array of API requests in case any need to be cancelled.
    var requests = [AnyCancellable]()
    
    // Load current workspace with all its members.
    func load(then handler: @escaping Handler) {
        // Get current workspace -- either its already been set or pull it from cache 
        currentWorkspace = currentWorkspace ?? Workspace.current
        
        // If current workspace alredy exists, refetch its members. Otherwise, fetch user workspces first.
        currentWorkspace == nil ? fetchUserWorkspaces(then: handler) : fetchWorkspaceMembers(then: handler)
    }
    
    // Fetch all workspaces for the current user.
    private func fetchUserWorkspaces(then handler: @escaping Handler) {
        let currentUser = User.current!
        
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
            
            // Fetch members now that current workspace has been determined.
            self.fetchWorkspaceMembers(then: handler)
            
        }.store(in: &requests)
    }
    
    // Fetch all members for the current workspace.
    private func fetchWorkspaceMembers(then handler: @escaping Handler) {
//        currentWorkspace!.fetchMembers().sink(receiveCompletion: { status in
//            switch status {
//            case .failure(let error):
//                handler(.failed(error))
//            default:
//                break
//            }
//        }) { (response: [Member]) in
//            // Set members on current workspace.
//            self.currentWorkspace!.members = response
//
//            // Tell workspace window that all has been loaded.
//            handler(.loaded(self.currentWorkspace))
//
//        }.store(in: &requests)
        
        // ----- Mock logic below ------
        
        // Set members on current workspace.
        self.currentWorkspace!.members = Mocks.Members.all

        // Tell workspace window that all has been loaded.
        handler(.loaded(self.currentWorkspace))
    }
}
