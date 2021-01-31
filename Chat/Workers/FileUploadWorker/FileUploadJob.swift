//
//  FileUploadJob.swift
//  Chat
//
//  Created by Ben Whittle on 1/30/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

public class FileUploadJob: Job {
        
    override var name: String { "file-upload-job" }
    
    private var file: File!
    
    private var data: Data!
    
    convenience init(file: File, data: Data) {
        self.init()
        self.file = file
        self.data = data
    }
    
    override init() {
        super.init()
    }
    
    override func run() throws {
        try? super.run()
        
        // Upload file to presigned file url.
        uploadFile(to: file.uploadURL, body: data) { [weak self] result, error in
            // Handle any errors.
            if let err = error {
                logger.error("File upload failed with error: \(err)")
                return
            }
           
            // Let server know file was successfully uploaded.
            self?.registerFileAsUploaded()
        }
    }
    
    private func uploadFile(to destination: String, body: Data, then handler: @escaping (Bool, Error?) -> Void) {
        // Create a URL object from the remote URL string.
        guard let url = URL(string: destination) else {
            handler(false, JobError.failed("invalid upload url -- \(destination)"))
            return
        }
        
        // Create HTTP request.
        let request = createUploadRequest(url: url, body: body)

        // Create upload task.
        let task = URLSession.shared.uploadTask(
            with: request,
            from: body,
            completionHandler: { data, response, error in
                // Handle any errors.
                if let err = error {
                    handler(false, err)
                    return
                }
                
                // Convert response so we can access status code.
                guard let resp = response as? HTTPURLResponse else {
                    handler(false, JobError.failed("invalid response object"))
                    return
                }
                        
                // Ensure successful status code.
                guard resp.statusCode == 200 else {
                    handler(false, JobError.failed("status code \(resp.statusCode)"))
                    return
                }
              
                // Return success.
                handler(true, nil)
            }
        )
        
        // Perform upload.
        task.resume()
    }
    
    private func createUploadRequest(url: URL, body: Data) -> URLRequest {
        // Create upload request.
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData
        )
        
        // Configure request headers.
        request.httpMethod = "PUT"
//        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        
        // TODO: Figure out any other header you need.

        return request
    }
    
    private func registerFileAsUploaded() {
        // File data provider --> patch
    }
}
