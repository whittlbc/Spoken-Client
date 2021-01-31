//
//  FileUploadJob.swift
//  Chat
//
//  Created by Ben Whittle on 1/30/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa
import Combine

public class FileUploadJob: Job {
        
    enum State {
        case initializing
        case running
        case succeeded
        case failed
    }
    
    private var state = State.initializing { didSet { onSetState() } }
    
    private let multipartChunkSize = 10000000 // 10MB

    override var name: String { "file-upload-job" }
    
    private var file: File!
    
    private var data: Data!
    
    private var isMultipartUpload: Bool!
    
    private var numParts: Int { file.uploadURLs.count }
    
    private var requestsCompleted = 0
    
    private var etags: [String]!
    
    private var registerResultCancellable: AnyCancellable?
    
    convenience init(file: File, data: Data) {
        self.init()
        self.file = file
        self.data = data
        self.isMultipartUpload = numParts > 1
        self.etags = [String](repeating: "", count: numParts)
    }
    
    override init() {
        super.init()
    }
        
    override func run() {
        super.run()
        
        // Register job as running,.
        toRunning()
        
        // Upload each part of the file to each respective pre-signed url (may not even be multipart).
        file.uploadURLs.enumerated().forEach { [weak self] (i, url) in
            uploadData(getChunk(forPart: i), to: url, forPart: i) { _, error in
                self?.handleUploadResponse(error: error)
            }
        }
    }
    
    private func handleUploadResponse(error: Error?) {
        requestsCompleted += 1
        
        // Register job as failed if error encountered.
        if let err = error {
            logger.error("File upload failed with error: \(err)")
            toFailed()
            return
        }
        
        // If all parts finished uploading, register success.
        if requestsCompleted == numParts {
            toSucceeded()
        }
    }
    
    private func toRunning() {
        state = .running
    }
    
    private func toSucceeded() {
        state = .succeeded
    }
    
    private func toFailed() {
        state = .failed
    }
    
    private func onSetState() {
        switch state {
        case .succeeded:
            registerUploadResult(FileUploadStatus.succeeded)
        case .failed:
            registerUploadResult(FileUploadStatus.failed)
        default:
            break
        }
    }
    
    private func getChunk(forPart index: Int) -> Data {
        // Calculate start index of chunk.
        let startIndex = index * multipartChunkSize
        
        // Calculate end index of chunk.
        var endIndex = (index + 1) * multipartChunkSize
        endIndex = endIndex > data.count ? data.count : endIndex
        
        return data.subdata(in: startIndex..<endIndex)
    }
    
    private func uploadData(
        _ body: Data,
        to destination: String,
        forPart partIndex: Int,
        then handler: @escaping (Bool, Error?) -> Void
    ) {
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
            completionHandler: { [weak self] _, response, error in
                self?.onRequestResponse(
                    forPart: partIndex,
                    response: response,
                    error: error,
                    handler: handler
                )
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
        
        // Use PUT for all uploads.
        request.httpMethod = "PUT"
        
        // Use file's mime type as the content-type header.
        request.setValue(file.mimeType, forHTTPHeaderField: "Content-Type")
        
        return request
    }
        
    private func onRequestResponse(
        forPart partIndex: Int,
        response: URLResponse?,
        error: Error?,
        handler: @escaping (Bool, Error?) -> Void
    ) {
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
        
        // Handler succeeded at this point if not a multipart upload.
        if !isMultipartUpload {
            handler(true, nil)
            return
        }
        
        // Extract etag from response headers.
        guard let etag = resp.value(forHTTPHeaderField: "etag") else {
            handler(false, JobError.failed("multipart upload failed to return etag"))
            return
        }
        
        // Assign etag to etags array for this part index.
        etags[partIndex] = etag
        
        // Return success.
        handler(true, nil)
    }
    
    private func registerUploadResult(_ status: FileUploadStatus) {
        registerResultCancellable = dataProvider.file
            .setUploadStatus(id: file.id, status: status, etags: etags)
            .asResult()
            .sink { [weak self] result in
                switch result {
                case .failure(let error):
                    logger.error("Error registering File(id=\(self?.file.id ?? "")) as \(status.rawValue): \(error)")
                default:
                    break
                }
            }
    }
}
