//
//  Array+Helpers.swift
//  Chat
//
//  Created by Ben Whittle on 1/16/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Foundation

extension Sequence where Iterator.Element: Hashable {
    
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}
