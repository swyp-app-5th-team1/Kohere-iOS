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
    private var requestsToRetry: [(RetryResult) -> Void] = []
    
    func enqueue(_ completion: @escaping (RetryResult) -> Void) -> Bool {
        requestsToRetry.append(completion)
        
        if isRefreshing {
            return false
        }
        
        isRefreshing = true
        return true
    }
    
    func complete(with result: RetryResult) {
        requestsToRetry.forEach { $0(result) }
        requestsToRetry.removeAll()
        isRefreshing = false
    }
}
