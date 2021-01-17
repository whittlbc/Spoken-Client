//
//  Publisher+Operators.swift
//  Chat
//
//  Created by Ben Whittle on 1/14/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Combine

extension Publisher {
    
    func asResult() -> AnyPublisher<Result<Output, Failure>, Never> {
        map(Result.success)
            .catch { error in
                Just(.failure(error))
            }
            .eraseToAnyPublisher()
    }
}

extension Publisher where Output: Sequence, Output.Element: Model {
    
    func sortBy<T: Model>(ids: [String]) -> Publishers.Map<Self, [T]>  {
        map { sequence in
            let elementsMap = sequence.reduce(into: [String: T]()) { $0[$1.id] = $1 as? T }
            var sortedSequence = [T]()
            
            for id in ids {
                if let element = elementsMap[id] {
                    sortedSequence.append(element)
                }
            }
            
            return sortedSequence
        }
    }
}
