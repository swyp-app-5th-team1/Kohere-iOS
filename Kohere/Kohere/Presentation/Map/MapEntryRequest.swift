//
//  MapEntryRequest.swift
//  Kohere
//
//  Created by Codex on 7/14/26.
//

enum MapEntryRequest: Equatable, Sendable {
    /// 진단 결과 없이 일반 매물을 탐색하기 위해 지도를 연다.
    /// 홈의 최근 본 매물 목록이 비었을 때 제공하는 '매물 둘러보기' 등에 사용한다.
    case browseListings
    case diagnosis(id: Int, filter: MapFilterState)
}
