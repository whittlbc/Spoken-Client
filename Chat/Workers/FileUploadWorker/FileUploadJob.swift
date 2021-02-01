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
    
    private var url: URL!
    
    private var isMultipartUpload: Bool!
    
    private var inputStream: InputStream?
    
    private var numParts: Int { file.uploadURLs.count }
    
    private var requestsCompleted = 0
    
    private var etags: [String]!
    
    private var registerResultCancellable: AnyCancellable?
    
    convenience init(file: File, url: URL) {
        self.init()
        self.file = file
        self.url = url
        self.isMultipartUpload = numParts > 1
        self.etags = [String](repeating: "", count: numParts)
    }
    
    override init() {
        super.init()
    }
        
    deinit {
        clearLocalFile()
        closeInputStream()
    }
    
    override func run() {
        super.run()
        
        // Register job as running,.
        toRunning()
        
        // Upload file in either the standard or multi-part fashion.
        isMultipartUpload ? runMultipartUpload() : runStandardUpload()
    }
    
    private func runStandardUpload() {
        // Read entire file contents as data.
        guard let data = readFileContents() else {
            toFailed()
            return
        }
        
        // Upload file contents.
        uploadData(data, to: file.uploadURLs[0], forPart: 0) { [weak self] _, error in
            self?.handleUploadResponse(error: error)
        }
    }
    
    private func runMultipartUpload() {
        // Create input stream from file url.
        createInputStream()
        
        // Ensure input stream was successfully created.
        guard let stream = inputStream else {
            logger.error("Input stream creation failed at URL: \(url.absoluteString)")
            toFailed()
            return
        }
        
        // Iterate over each pre-signed upload url...
        file.uploadURLs.enumerated().forEach { (i, url) in
            // Get next chunk of file from the input stream.
            let chunk = Data(reading: stream, for: multipartChunkSize)
            
            // Upload chunk as part.
            uploadData(chunk, to: url, forPart: i) { [weak self] _, error in
                self?.handleUploadResponse(error: error)
            }
        }
    }
    
    private func handleUploadResponse(error: Error?) {
        guard isRunning() else {
            return
        }
        
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
    
    private func isRunning() -> Bool {
        state == .running
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
        
        // Upload succeeded.
        case .succeeded:
            registerUploadResult(FileUploadStatus.succeeded)
            
        // Upload failed.
        case .failed:
            registerUploadResult(FileUploadStatus.failed)

        default:
            break
        }
    }
    
    private func readFileContents() -> Data? {
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            logger.error("Error reading URL\(url.absoluteString) contents into Data object: \(error)")
            return nil
        }
    }
    
    private func createInputStream() {
        inputStream = InputStream(url: url)
        inputStream?.open()
    }
    
    private func nextChunk(forPart index: Int) -> Data {
        Data(reading: inputStream!, for: multipartChunkSize)
    }
    
    private func uploadData(
        _ data: Data,
        to destination: String,
        forPart partIndex: Int,
        then handler: @escaping (Bool, Error?) -> Void
    ) {
        // Create a URL object from the remote URL string.
        guard let url = URL(string: destination) else {
            handler(false, JobError.failed("invalid upload url -- \(destination)"))
            return
        }
        
        // Create upload task.
        let task = URLSession.shared.uploadTask(
            with: createUploadRequest(url: url),
            from: data,
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
    
    private func createUploadRequest(url: URL) -> URLRequest {
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
    
    // Let the server know if the file uploaded successfully or not.
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
    
    // Remove the file at the given url (should just be a temp file).
    private func clearLocalFile() {
        try? FileManager.default.removeItem(at: url)
    }
    
    // Close input stream.
    private func closeInputStream() {
        inputStream?.close()
    }
}
