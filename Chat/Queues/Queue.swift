//
//  Queue.swift
//  Chat
//
//  Created by Ben Whittle on 2/1/21.
//  Copyright © 2021 Ben Whittle. All rights reserved.
//

import Cocoa

public class Queue<T> {
    
    typealias Pipe = (T) -> Void

    var isRunning = false
    
    let name: String

    let threadName: String
    
    private var thread: DispatchQueue?
    
    private var items = [T]()
    
    private var pipe: Pipe!
    
    init(name: String, threadName: String) {
        self.name = name
        self.threadName = threadName
        self.pipe = { t in } // No-op
    }

    func start(then handler: @escaping Pipe) {
        // Ensure not already running.
        if isRunning {
            return
        }
        
        // Use provided handler as pipe.
        pipe = handler
        
        // Upsert background thread.
        upsertThread()
        
        // Register queue as running.
        isRunning = true
        
        // Wait for items forever (unless paused).
        thread!.async {
            while self.isRunning {
                self.popItem()
            }
        }
    }
    
    func pause() {
        isRunning = false
    }
    
    func addItem(_ item: T) {
        items.insert(item, at: 0)
    }
    
    private func upsertThread() {
        thread = thread ?? Thread.newBackgroundThread(name: threadName)
    }
    
    // Process items in queue in a FIFO manner.
    private func popItem() {
        // Ensure at least one item exists.
        guard items.count > 0 else {
            return
        }
        
        // Pop last item off the queue.
        let item = items.removeLast()
        
        // Send item through the current pipe.
        pipe(item)
    }
}
