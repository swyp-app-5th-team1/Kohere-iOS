//
//  DiagnosisRouter.swift
//  Kohere
//
//  Created by Codex on 7/4/26.
//

import Alamofire
import Foundation

enum DiagnosisRouter: URLRequestConvertible {
    case startFlow(environment: APIEnvironment)
    case advanceFlow(
        DiagnosisAnswerRequestDTO,
        guestSessionID: String?,
        environment: APIEnvironment
    )
    case question(step: Int, environment: APIEnvironment)
    case saveAnswer(DiagnosisAnswerRequestDTO, environment: APIEnvironment)
    case submit(environment: APIEnvironment)
    case detail(diagnosisID: Int, APIEnvironment)
    case recommendations(
        diagnosisID: Int,
        query: DiagnosisRecommendationsQueryDTO,
        guestSessionID: String?,
        APIEnvironment
    )
    case recommendationMap(diagnosisID: Int, guestSessionID: String?, APIEnvironment)

    private var method: HTTPMethod {
        switch self {
        case .question, .detail, .recommendations, .recommendationMap:
            .get

        case .startFlow, .advanceFlow, .saveAnswer, .submit:
            .post
        }
    }

    private var path: String {
        switch self {
        case .startFlow:
            "api/v2/diagnoses/start"

        case .advanceFlow:
            "api/v2/diagnoses/next"

        case let .question(step, _):
            "api/v1/diagnoses/questions/\(step)"

        case .saveAnswer:
            "api/v1/diagnoses/answers"

        case .submit:
            "api/v1/diagnoses"

        case let .detail(diagnosisID, _):
            "api/v1/diagnoses/\(diagnosisID)"

        case let .recommendations(diagnosisID, _, _, _):
            "api/v2/diagnoses/\(diagnosisID)/recommendations"
        case let .recommendationMap(diagnosisID, _, _):
            "api/v2/diagnoses/\(diagnosisID)/recommendations/map"
        }
    }

    private var environment: APIEnvironment {
        switch self {
        case let .startFlow(environment),
             let .advanceFlow(_, _, environment),
             let .question(_, environment),
             let .saveAnswer(_, environment),
			 let .submit(environment),
			 let .detail(_, environment),
             let .recommendations(_, _, _, environment),
             let .recommendationMap(_, _, environment):
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
        case let .recommendations(_, query, _, _):
            request = try URLEncodedFormParameterEncoder.default.encode(query, into: request)

        case let .advanceFlow(requestDTO, _, _),
             let .saveAnswer(requestDTO, _):
            request = try JSONParameterEncoder.default.encode(requestDTO, into: request)

        case .startFlow, .detail, .question, .submit, .recommendationMap:
            break
        }

        if let guestSessionID {
            request.setValue(guestSessionID, forHTTPHeaderField: "X-Guest-Session-Id")
        }

        return request
    }

    private var guestSessionID: String? {
        switch self {
        case let .advanceFlow(_, guestSessionID, _),
             let .recommendations(_, _, guestSessionID, _),
             let .recommendationMap(_, guestSessionID, _):
            guestSessionID

        case .startFlow, .question, .saveAnswer, .submit, .detail:
            nil
        }
    }
}
