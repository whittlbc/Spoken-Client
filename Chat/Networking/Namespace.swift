//
//  Namespace.swift
//  Chat
//
//  Created by Ben Whittle on 1/12/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation
import Networking

class Namespace<T: NetworkingJSONDecodable> {
    
    let nsp: String
    
    weak var api: API?
    
    init(api: API, nsp: String) {
        self.api = api
        self.nsp = nsp
    }

    func get(id: T) {

    }
}
