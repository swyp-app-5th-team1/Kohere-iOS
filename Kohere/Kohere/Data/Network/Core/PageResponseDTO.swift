//
//  PageResponseDTO.swift
//  Kohere
//
//  Created by Codex on 8/6/26.
//

/// 서버 페이지네이션 응답의 공통 규격.
///
/// 매물 검색, 진단 추천, 예약 목록이 모두 같은 `page` 객체를 내려주므로 도메인별로 나누지 않는다.
/// 서버가 `hasNext`를 직접 내려주기 때문에 유도 로직 없이 그대로 매핑한다.
struct PageResponseDTO: Decodable {
    let number: Int?
    let size: Int?
    let totalElements: Int?
    let totalPages: Int?
    let hasNext: Bool?
}

extension PageResponseDTO {
    func toEntity() -> PageInfo {
        PageInfo(
            number: number,
            size: size,
            totalElements: totalElements,
            totalPages: totalPages,
            hasNext: hasNext
        )
    }
}
