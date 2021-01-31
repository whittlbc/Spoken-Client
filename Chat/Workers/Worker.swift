//
//  Worker.swift
//  Chat
//
//  Created by Ben Whittle on 1/30/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

public class Worker<T: Job> {

    var isRunning = false
    
    let name: String

    let threadName: String
    
    private var thread: DispatchQueue?
    
    private var jobsQueue = [T]()
    
    init(name: String, threadName: String) {
        self.name = name
        self.threadName = threadName
    }

    func start() {
        upsertThread()
        
        isRunning = true
        
        thread!.async {
            while self.isRunning {
                self.processJobs()
            }
        }
    }
    
    func pause() {
        isRunning = false
    }
    
    func addJob(_ job: T) {
        jobsQueue.insert(job, at: 0)
    }
    
    private func upsertThread() {
        thread = thread ?? Thread.newBackgroundThread(name: threadName)
    }
    
    // Process jobs from queue in a FIFO manner.
    private func processJobs() {
        // Ensure at least one job exists.
        guard jobsQueue.count > 0 else {
            return
        }
        
        // Pop last job off the queue.
        let job = jobsQueue.removeLast()
        
        // Run the job.
        job.run()
    }
}
