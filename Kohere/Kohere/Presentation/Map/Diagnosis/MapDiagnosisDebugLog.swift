//
//  MapDiagnosisDebugLog.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

import Foundation

func debugLogDiagnosisDetail(_ detail: DiagnosisDetail) {
#if DEBUG
    print("[MapFeature] diagnosis detail response:", detail)
#endif
}

func debugLogDiagnosisRecommendations(_ recommendations: DiagnosisRecommendations) {
#if DEBUG
    print("[MapFeature] diagnosis recommendations response:", recommendations)
#endif
}

func debugLogDiagnosisError(_ endpoint: String, _ error: Error) {
#if DEBUG
    print("[MapFeature] diagnosis \(endpoint) request failed:", error.localizedDescription)
#endif
}
