# Progress

이 문서는 Kohere의 현재 상태, 결정 사항, 최근 작업 로그를 기록한다.

상세 기능 계획과 미확정 요구사항은 `docs/planning.md`에 기록한다.
학습할 개념과 참고 주제는 `docs/learning.md`에 기록한다.

## Current Status

- 하네스 초안 구축 중.
- 디자인 시스템 구조 규칙 일부 확정.
- SwiftUI + TCA 기반 아키텍처 방향 확정.
- TCA 기반 탭바와 탭별 NavigationStack 골격 구축.

## Decisions

- 2026-06-15: 디자인 시스템 문서의 1차 구조를 작성했다.
- 2026-06-15: `docs/progress.md`는 hybrid 방식으로 운영한다. 현재 상태, 결정 사항, 최근 로그를 기록하되 작은 작업 로그는 필요 시 정리한다.
- 2026-06-15: 기능 계획과 미확정 요구사항은 `docs/planning.md`로 분리한다.
- 2026-06-15: 취업 준비와 학습을 위해 CS/iOS 학습 주제는 `docs/learning.md`에 분리 기록한다.
- 2026-06-15: 커밋 메시지는 `type: 한국어 내용` 형식을 사용한다.
- 2026-06-18: 기본 탭 구조는 홈, 커뮤니티, 지도, 채팅, 더보기 순서로 구성한다.
- 2026-06-18: 탭별 화면 이동 골격은 TCA `StackState`와 Feature 내부 `@Reducer enum Path` 기반으로 구성한다.
- 2026-06-18: 탭 루트 화면은 route/path destination case로 두지 않고, 추가 depth 화면만 destination case로 추가한다.

## Pending

- Elevation/Shadow 구현 방식 구체화.
- 실제 depth 화면 추가 시 TCA navigation destination case 작성 방식 학습 및 예시 보강.

## Next Tasks

- `docs/planning.md` 운영 기준 구체화.
- `docs/learning.md`에 학습 주제 기록 방식 구체화.
- 첫 상세 화면 구현 시 탭 Feature 내부 `Path`에 destination Feature case 추가 예시 보강.

## Recent Log

- 2026-06-15: `AGENTS.md`, `docs/design-system.md`, `docs/architecture.md`, `docs/progress.md` 초안 작성.
- 2026-06-18: TCA 기반 `RootFeature`, `RootView`, 탭별 Feature/FlowView/Path/View placeholder를 추가했다.
