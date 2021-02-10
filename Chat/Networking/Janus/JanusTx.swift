//
//  JanusTx.swift
//  Chat
//
//  Created by Ben Whittle on 2/9/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

typealias JanusTxBlock = (JanusTxResponseMessage) -> Void

class JanusTx {
    
    static func newId() -> String { String.random(length: 12) }
    
    var id: String!

    var onSuccess: JanusTxBlock
    
    var onError: JanusTxBlock
    
    init(id: String? = nil, onSuccess: @escaping JanusTxBlock, onError: @escaping JanusTxBlock) {
        self.id = id ?? JanusTx.newId()
        self.onSuccess = onSuccess
        self.onError = onError
    }
}
