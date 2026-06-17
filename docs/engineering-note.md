# Engineering Note

이 문서는 구현 과정에서 검토한 기술 선택지와 결정 이유를 기록한다.

## 2026-06-18 Navigation Structure

### Context

기본 탭바와 탭별 화면 이동 구조를 만들기 전에 두 가지 방식을 검토했다.

1. SwiftUI `NavigationStack` + `Route enum` + 별도 Router/Flow 계층.
2. TCA `StackState` + 탭별 Feature 내부 `@Reducer enum Path`.

탭 구조는 홈, 커뮤니티, 지도, 채팅, 더보기 순서로 확정했다.
탭바는 라벨 없이 아이콘만 표시한다.

### Considered Options

#### Router/Route 방식

장점:
- 구조가 직관적이고 초기 구현이 빠르다.
- `NavigationStack(path:)`와 route enum의 동작을 이해하기 쉽다.
- 단순한 값 전달과 push 처리에는 코드가 적다.

단점:
- 화면 이동 상태가 TCA feature tree 밖에 놓일 수 있다.
- push된 하위 화면이 API 요청, 로딩, 에러, 저장 같은 상태를 가지기 시작하면 TCA와 navigation 책임이 섞일 수 있다.
- 딥링크, 푸시 알림, 로그인 전환처럼 전역 이동 정책이 커질 때 별도 Router와 TCA State의 동기화 기준이 필요하다.

#### TCA StackState 방식

장점:
- navigation stack 자체가 Feature State에 포함된다.
- push된 화면도 각자의 State/Action/Reducer를 가질 수 있다.
- 화면 이동과 하위 화면 상태를 테스트 가능한 reducer 흐름으로 관리할 수 있다.
- 프로젝트의 SwiftUI + TCA 아키텍처 방향과 일관된다.

단점:
- 초기 학습 비용이 높다.
- 아직 실제 depth 화면이 없는 상태에서는 구조가 과하게 느껴질 수 있다.
- 첫 destination을 붙일 때 Path State/Action과 `.forEach` 연결 방식을 학습해야 한다.

### Decision

Kohere는 하위 화면에서도 API 요청과 상태 관리가 발생할 가능성이 높으므로 TCA `StackState` 기반 골격을 사용한다.

이번 작업에서는 실제 destination case를 만들지 않고, 탭 Feature 내부에 빈 `@Reducer enum Path`와 `StackState<Path.State>`만 준비한다.
첫 상세 화면이 생길 때 해당 탭의 `Path`에 destination Feature case를 추가한다.

### Implementation Notes

- `RootFeature`는 `selectedTab`과 탭별 Feature State를 가진다.
- `RootView`는 `TabView(selection:)`을 구성한다.
- 각 탭은 `<TabName>Feature`, `<TabName>FlowView`, `<TabName>View`를 가진다.
- destination 경로는 `<TabName>Feature` 내부의 `@Reducer enum Path`로 관리한다.
- 루트 화면은 Path destination case로 만들지 않는다.
- Path destination case는 루트 위에 push될 화면만 추가한다.
- 현재는 실제 destination이 없으므로 `Path`는 빈 enum으로 두고, 첫 destination이 생길 때 `case detail(DetailFeature)` 같은 형태로 추가한다.
