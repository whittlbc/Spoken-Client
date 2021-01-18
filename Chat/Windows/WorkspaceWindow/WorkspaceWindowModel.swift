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
    
    var workspace: Workspace?

    private var workspaceResult = WorkspaceResult.success(Workspace()) {
        didSet {
            switch workspaceResult {
            case .success(let workspace):
                self.workspace = workspace
                state = .loaded(workspace)
            case .failure(let error):
                state = .failed(error)
            }
        }
    }

    private var cancellable: AnyCancellable?
    
    func isLoading() -> Bool {
        switch state {
        case .loading:
            return true
        default:
            return false
        }
    }
    
    func showLoading() {
        if !isLoading() {
            state = .loading
        }
    }
    
    func loadWorkspace(silently: Bool = false) {
        if !silently {
            showLoading()
        }
        
        // Get current workspace.
        cancellable = dataProvider.workspace
            .current(withChannels: true, withMembers: true, withUsers: true)
            .asResult()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.workspaceResult = result
            }
    }
}
