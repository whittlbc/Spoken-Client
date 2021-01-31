//
//  FileDataProvider.swift
//  Chat
//
//  Created by Ben Whittle on 1/30/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Networking
import Combine

class FileDataProvider<T: Model & NetworkingJSONDecodable>: DataProvider<T> {

    convenience init() {
        self.init(cacheCountLimit: 200)
    }
    
    override init(cacheCountLimit: UInt = 0) {
        super.init(cacheCountLimit: cacheCountLimit)
    }
    
    func setUploadStatus(id: String, status: FileUploadStatus, etags: [String]) -> AnyPublisher<T, Error> {
        patch("/upload-status", params: ["id": id, "status": status.rawValue, "etags": etags])
    }
}
