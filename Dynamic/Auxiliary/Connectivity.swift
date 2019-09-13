//
//  Connectivity.swift
//  Dynamic Dark Mode
//
//  Created by Apollo Zhu on 5/4/19.
//  Copyright © 2019 Dynamic Dark Mode. All rights reserved.
//

import Network

public final class Connectivity {
    private var monitor: NWPathMonitor!
    private let queue: DispatchQueue
    public init(label: String) {
        self.queue = DispatchQueue(label: label)
    }
    public static let `default` = Connectivity(label: "Connectivity")
    
    private var isObserving = false
    private var isInitialUpdate = true
    public func startObserving(onSuccess: @escaping () -> Void) {
        stopObserving()
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            guard !self.isInitialUpdate else {
                self.isInitialUpdate = false
                return
            }
            switch path.status {
            case .satisfied:
                onSuccess()
            case .requiresConnection, .unsatisfied:
                break
            @unknown default:
                remindReportingBug("\(path.status)")
            }
        }
        monitor.start(queue: queue)
        isObserving = true
    }
    
    public func stopObserving() {
        guard isObserving else { return }
        isInitialUpdate = true
        monitor.cancel()
        isObserving = false
        taskCount = 0
    }
    
    private var taskCount: UInt64 = 0
    public func scheduleWhenReconnected() {
        startObserving { [weak self] in
            self?.taskCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                guard let self = self else { return }
                defer {
                    if self.taskCount > 0 {
                        self.taskCount -= 1
                    }
                }
                guard self.taskCount <= 1 else { return }
                Scheduler.shared.schedule()
            }
        }
    }
}
