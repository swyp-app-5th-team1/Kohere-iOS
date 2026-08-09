//
//  PageInfo.swift
//  Kohere
//
//  Created by Codex on 8/6/26.
//

/// 서버 페이지네이션 응답의 공통 메타 정보.
///
/// 매물 검색, 진단 추천, 예약 목록이 모두 같은 규격을 사용하므로 도메인별로 나누지 않고 하나로 둔다.
/// DTO에서 이 타입으로 변환하는 방식은 응답 필드가 도메인마다 달라 각 Repository가 담당한다.
nonisolated struct PageInfo: Equatable {
    let number: Int?
    let size: Int?
    let totalElements: Int?
    let totalPages: Int?
    let hasNext: Bool?
}
