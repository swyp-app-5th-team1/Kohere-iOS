//
//  Auth.swift
//  Kohere
//
//  Created by mandoo on 6/18/26.
//

import Foundation

struct Auth: Equatable {
    let userId: Int
    let email: String
    let accessToken: String
    let refreshToken: String
}
