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
    
    typealias WorkspaceResult = Result<[Workspace], Error>
    
    enum State {
        case loading
        case loaded([Workspace]?)
        case failed(Error)
    }
    
    @Published private(set) var state = State.loading
    
    var workspaces: [Workspace]?
    
    var channels: [Channel]? { workspaces?.map(\.channel) }

    private var results = WorkspaceResult.success([Workspace()]) {
        didSet {
            switch results {
            case .success(let workspaces):
                self.workspaces = workspaces
                state = .loaded(workspaces)
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
    
    func loadWorkspaces(silently: Bool = false) {
        if !silently {
            showLoading()
        }
        
        // Get current workspace.
        cancellable = dataProvider.workspace
            .currentWorkspaces(withChannels: true, withMembers: true, withUsers: true)
            .asResult()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                self?.results = results
            }
    }
}
