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
