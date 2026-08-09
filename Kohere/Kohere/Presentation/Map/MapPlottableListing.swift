//
//  MapPlottableListing.swift
//  Kohere
//
//  Created by Codex on 8/6/26.
//

/// 지도에 마커로 찍을 수 있는 매물.
///
/// 위치 검색 결과(`Listing`)와 진단 추천 결과(`DiagnosisRecommendedListing`)는 서로 다른 타입이지만
/// 지도 입장에서는 "ID와 좌표를 가진 매물"이라는 점만 같으면 된다.
///
/// "지도에 찍힐 수 있다"는 것은 화면 사정이므로 Domain 엔티티가 알 필요가 없다.
/// 그래서 프로토콜과 conformance를 모두 Presentation 계층에 둔다.
protocol MapPlottableListing: Identifiable where ID == String {
    var coordinate: MapCoordinate? { get }
}

extension Listing: MapPlottableListing {}

extension DiagnosisRecommendedListing: MapPlottableListing {}

extension Array where Element: MapPlottableListing {
    /// 좌표가 있는 매물만 지도 마커로 변환한다. 좌표가 없는 매물은 제외된다.
    nonisolated var markerItems: [MapMarkerItem] {
        compactMap { listing in
            listing.coordinate.map { MapMarkerItem(id: listing.id, coordinate: $0) }
        }
    }
}
