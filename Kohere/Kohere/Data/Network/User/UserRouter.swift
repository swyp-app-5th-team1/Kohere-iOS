//
//  UserRouter.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import Alamofire
import Foundation

enum UserRouter: URLRequestConvertible {
    case me(APIEnvironment)
    case notificationPreferences(APIEnvironment)
    case updateNotificationPreferences(UpdateNotificationPreferencesRequestDTO, APIEnvironment)
    case updateProfile(UpdateProfileRequestDTO, APIEnvironment)
    case deleteMe(APIEnvironment)

    private var method: HTTPMethod {
        switch self {
        case .me, .notificationPreferences:
            .get

        case .updateProfile, .updateNotificationPreferences:
            .patch

        case .deleteMe:
            .delete
        }
    }

    private var path: String {
        switch self {
        case .me, .updateProfile, .deleteMe:
            "api/v1/users/me"

        case .notificationPreferences, .updateNotificationPreferences:
            "api/v1/users/me/notification-preferences"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .me(environment),
             let .notificationPreferences(environment),
             let .updateNotificationPreferences(_, environment),
             let .updateProfile(_, environment),
             let .deleteMe(environment):
            environment
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = environment.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        switch self {
        case let .updateProfile(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case let .updateNotificationPreferences(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case .me, .notificationPreferences, .deleteMe:
            break
        }

        return request
    }
}
