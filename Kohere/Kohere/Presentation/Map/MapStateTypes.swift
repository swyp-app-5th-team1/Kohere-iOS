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

/// 카메라가 멈췄을 때(viewport 변경) 무엇을 할지 정한다. 진입 경로가 알맞은 case를 넣어 두고, `MapFeature+Viewport`가 이 값만 보고 판단한다.
enum MapViewportSearchTrigger: Equatable {
    /// 아직 검색 기준 영역이 없다. 위치 검색은 첫 멈춤에 바로 검색하고, 진단은 첫 멈춤 영역을 재검색 기준으로 기록만 한다.
    /// 예: 지도 탭 첫 진입, 지도가 그려지기 전의 매물 둘러보기, 진단 진입
    case onFirstIdle
    /// 앱이 카메라를 옮겼다. 목표 좌표가 화면에 들어온 멈춤에서만 검색하고, 그 전 멈춤(초기 카메라 등)은 무시한다.
    /// 예: 장소 검색 결과 선택, 매물 상세의 지도 보기
    case onArrival(at: MapCoordinate)
    /// 한 번이라도 검색한 뒤의 평소 상태. 영역이 기준과 달라지면 재검색 버튼만 띄운다.
    /// 예: 사용자가 손으로 지도를 끌었을 때
    case manual(lastSearched: MapViewport)

    /// 마지막으로 검색한 영역. 아직 검색 전이면 nil이다.
    var lastSearchedViewport: MapViewport? {
        if case let .manual(viewport) = self { viewport } else { nil }
    }
}

struct MapCameraMoveRequest: Equatable {
    let coordinate: MapCoordinate
    let targetPosition: MapCameraTargetPosition
}

enum MapCameraTargetPosition: Equatable {
    case center
    case upper
}
