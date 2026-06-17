# Architecture

이 문서는 Kohere의 iOS 아키텍처와 코드 구조 기준을 정리한다.

Kohere는 SwiftUI와 TCA를 기반으로 구성한다.

## Naming

폴더명은 단수형을 사용한다.
예: `Resource`, `Feature`, `Entity`, `UseCase`.
여러 구현 파일을 묶는 category folder도 단수형으로 이름 붙인다.

## Layers

### App

앱 엔트리 포인트와 앱 전역 조립을 담당한다.

예:
- `KohereApp.swift`
- Root feature / root reducer
- 앱 전역 dependency 조립

### Core

앱 전역 기반 코드를 둔다.

- `Core/DesignSystem`: 색상, 타이포그래피, shadow 등 앱 디자인 시스템 API.
- `Core/Extensions`: Foundation, SwiftUI, UIKit 등 범용 타입 extension.

디자인 시스템을 표현하는 extension은 일반 extension으로 보지 않고 `Core/DesignSystem` 안에 둔다.
예: `Color.primaryNormal`, `View.kohereTextStyle(_:)`.

특정 화면이나 기능에서만 쓰이는 extension은 Core에 두지 않고 해당 feature 폴더에 둔다.

### Presentation

SwiftUI View와 TCA Feature를 기능 단위로 관리한다.

기능 폴더는 기본적으로 다음 파일을 가진다.

- `<FeatureName>View.swift`
- `<FeatureName>Feature.swift`

`<FeatureName>Feature.swift`는 TCA의 State, Action, Reducer body를 포함한다.

## Navigation

앱의 기본 탭 구조는 `RootFeature`와 `RootView`에서 관리한다.

- 탭 선택 상태는 `RootFeature.State.selectedTab`으로 관리한다.
- 탭은 `AppTab` enum으로 표현한다.
- 탭 순서는 홈, 커뮤니티, 지도, 채팅, 더보기 순서로 둔다.
- 탭바는 아이콘만 노출하고 화면 라벨은 표시하지 않는다.
- 각 탭은 하나의 `FlowView`를 가진다.
- 각 `FlowView`는 해당 탭의 `NavigationStack`을 담당한다.
- 각 탭 Feature는 `StackState` 기반 path를 가진다.
- 각 탭의 push destination은 탭 Feature 내부의 `@Reducer enum Path`에서 관리한다.
- 루트 화면은 path destination case로 만들지 않는다.
- 추가 depth 화면은 실제 화면 요구사항이 생길 때 `Path`에 destination Feature case로 추가한다.

예:

```text
RootView
└─ TabView
   ├─ HomeFlowView
   ├─ CommunityFlowView
   ├─ MapFlowView
   ├─ ChatFlowView
   └─ MoreFlowView
```

일반 View는 navigation path를 직접 수정하지 않는다.
사용자 액션은 TCA Action으로 Feature에 전달하고, push/pop 같은 화면 전환 상태 변경은 Feature reducer 또는 Flow 계층에서 처리한다.

탭별 Feature는 다음 형태를 기본 골격으로 사용한다.

```swift
@Reducer
struct HomeFeature {
    @Reducer
    enum Path {
        // case detail(DetailFeature)
    }

    @ObservableState
    struct State: Equatable {
        var path = StackState<Path.State>()
    }

    enum Action {
        case path(StackActionOf<Path>)
    }

    var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .path:
                return .none
            }
        }
    }
}

extension HomeFeature.Path.State: Equatable {}
```

### Domain

순수 비즈니스 로직을 담당한다.

구성:
- `Entity`
- `UseCase`
- `Interface`

UseCase는 비즈니스 로직 인터페이스와 구현체를 포함할 수 있다.
TCA에서 필요한 의존성 등록은 별도 dependency 파일로 관리한다.

### Data

외부 데이터 소스, 네트워크 통신, DTO 변환을 담당한다.

구성:
- `Repository`
- `Network`

Repository는 DTO 검증, 도메인 에러 매핑, Entity 변환을 담당한다.
Network는 순수 통신과 제네릭 디코딩을 담당한다.

### Resource

앱 리소스를 관리한다.

예:
- Assets
- xcconfig
- Info.plist

## Scope Rule

단순 UI 또는 디자인 시스템 작업에는 Domain/Data 계층을 억지로 만들지 않는다.
기능 요구사항이 비즈니스 로직, 외부 데이터, 저장소 의존성을 가질 때 필요한 계층을 추가한다.
