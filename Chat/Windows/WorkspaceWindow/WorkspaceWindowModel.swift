//
//  WorkspaceWindowModel.swift
//  Chat
//
//  Created by Ben Whittle on 1/14/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Combine

class WorkspaceWindowModel {
    
    typealias WorkspaceResult = Result<Workspace, Error>
    
    enum State {
        case loading
        case loaded(Workspace?)
        case failed(Error)
    }
    
    @Published private(set) var state = State.loading

    private var workspaceResult = WorkspaceResult.success(Workspace()) {
        didSet { updateStateWithWorkspaceResult() }
    }

    private var cancellable: AnyCancellable?

    var workspace: Workspace? { getCurrentWorkspace() }
    
    var channels: [Channel] { getCurrentChannels() }
    
    func loadWorkspace() {
        // Set state to loading.
        state = State.loading
        
        // Get current workspace.
        cancellable = dataProvider.workspace
            .current()
            .asResult()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.workspaceResult = result
            }
    }
    
    private func updateStateWithWorkspaceResult() {
        switch workspaceResult {
        case .success(let workspace):
            state = .loaded(workspace)
        case .failure(let error):
            state = .failed(error)
        }
    }
    
    private func getCurrentWorkspace() -> Workspace? {
        switch state {
        case .loaded(let workspace):
            return workspace
        default:
            return nil
        }
    }
    
    private func getCurrentChannels() -> [Channel] {
        guard let ws = workspace else {
            return []
        }
        
        return ws.channels ?? []
    }
}
