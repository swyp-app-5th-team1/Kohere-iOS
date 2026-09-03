//
//  PushDeviceRequestDTO.swift
//  Kohere
//
//  Created by 송규섭 on 9/1/26.
//

import Foundation

nonisolated struct RegisterPushDeviceRequestDTO: Encodable, Sendable {
    let fcmToken: String
    let platform: String

    init(fcmToken: String) {
        self.fcmToken = fcmToken
        self.platform = "IOS"
    }
}
