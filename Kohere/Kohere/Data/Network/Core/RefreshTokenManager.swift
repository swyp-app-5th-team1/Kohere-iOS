//
//  RefreshTokenManager.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import Alamofire
import Foundation

actor RefreshTokenManager {
    private var isRefreshing = false
    private var activeAttemptID: String?
    private var requestsToRetry: [(RetryResult) -> Void] = []
    
    func enqueue(_ completion: @escaping (RetryResult) -> Void) -> RefreshEnqueueDecision {
        requestsToRetry.append(completion)
        
        if isRefreshing, let activeAttemptID {
            return RefreshEnqueueDecision(
                attemptID: activeAttemptID,
                shouldStartRefresh: false
            )
        }
        
        let attemptID = String(UUID().uuidString.prefix(8))
        isRefreshing = true
        activeAttemptID = attemptID
        return RefreshEnqueueDecision(
            attemptID: attemptID,
            shouldStartRefresh: true
        )
    }
    
    func complete(with result: RetryResult) {
        requestsToRetry.forEach { $0(result) }
        requestsToRetry.removeAll()
        isRefreshing = false
        activeAttemptID = nil
    }
}

struct RefreshEnqueueDecision: Equatable, Sendable {
    let attemptID: String
    let shouldStartRefresh: Bool
}
