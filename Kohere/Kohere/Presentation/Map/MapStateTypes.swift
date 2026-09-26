//
//  MapStateTypes.swift
//  Kohere
//
//  Created by Codex on 7/5/26.
//

enum MapSheetMode: Equatable {
    case listingList
    case selectedListing
}

/// 목록과 마커를 어느 API 결과로 채우는지. appliedFilterSource와의 관계는 MapFeature.State 참고.
enum MapListingSource: Equatable {
    case idle
    case locationSearch
    case diagnosis
}

/// 적용된 필터가 진단 조건인지. 표시용이며 목록 데이터 출처와는 별개다.
enum MapFilterApplicationSource: Equatable {
    case manual
    case diagnosis
}

struct MapCameraMoveRequest: Equatable {
    let coordinate: MapCoordinate
    let targetPosition: MapCameraTargetPosition
}

enum MapCameraTargetPosition: Equatable {
    case center
    case upper
}
