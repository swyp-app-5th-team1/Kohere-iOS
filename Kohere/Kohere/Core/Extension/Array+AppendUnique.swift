//
//  Array+AppendUnique.swift
//  Kohere
//
//  Created by Codex on 8/6/26.
//

extension Array where Element: Identifiable {
    /// 기존 원소와 ID가 겹치지 않는 항목만 골라 뒤에 이어붙인다.
    ///
    /// 페이지네이션으로 받은 다음 페이지를 기존 목록에 누적할 때 사용한다.
    ///
    /// 구현 배경:
    /// - 결과가 `Set`이 아니라 배열인 이유는 순서가 의미를 갖기 때문이다.
    ///   서버가 준 정렬(거리순, 추천순)을 유지해야 하고, 마지막 원소가 화면에 나타나는 시점으로
    ///   다음 페이지 로드를 판단한다. `Set`으로 바꾸면 둘 다 깨진다.
    ///   여기서 쓰는 `Set`은 저장소가 아니라 O(1) 중복 판정을 위한 조회 인덱스다.
    /// - 중복 판정을 원소 값이 아니라 ID로 하는 이유는, 같은 항목이라도 좋아요 수처럼
    ///   변하는 값이 섞여 있어 값 비교로는 같은 항목을 걸러내지 못하기 때문이다.
    /// - `contains`가 아니라 `insert(_:).inserted`를 쓰는 이유는, 필터를 도는 동안 `Set`이 자라므로
    ///   기존 목록과의 중복뿐 아니라 `newElements` 내부의 중복까지 함께 걸러지기 때문이다.
    nonisolated mutating func appendUnique(contentsOf newElements: [Element]) {
        var existingIDs = Set(map(\.id))
        append(contentsOf: newElements.filter { existingIDs.insert($0.id).inserted })
    }
}
