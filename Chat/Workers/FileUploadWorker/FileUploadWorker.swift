//
//  FileUploadWorker.swift
//  Chat
//
//  Created by Ben Whittle on 1/30/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

public let fileUploadWorker = Worker<FileUploadJob>(
    name: "file-upload-worker",
    threadName: "file-upload"
)
