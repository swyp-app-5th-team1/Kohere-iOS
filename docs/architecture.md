# Architecture

이 문서는 Kohere의 iOS 아키텍처와 코드 구조 기준을 정리한다.

Kohere는 SwiftUI와 TCA를 기반으로 구성한다.

## Naming

폴더명은 단수형을 사용한다.
예: `Resource`, `Feature`, `Entity`, `UseCase`.
여러 구현 파일을 묶는 category folder도 단수형으로 이름 붙인다.

## Project Folder Structure
프로젝트의 전체 디렉터리 계층 구조는 다음과 같은 구조적 규칙을 따른다. 특정 도메인이나 화면에 종속되지 않도록 `<FeatureName>`과 `<DomainName>`으로 추상화하여 정의한다.

```text
Kohere/
├── App/
│   ├── KohereApp.swift
│   └── Root/
│       ├── RootView.swift
│       └── RootFeature.swift
├── Presentation/
│   └── <FeatureName>/
│       ├── <FeatureName>View.swift
│       └── <FeatureName>Feature.swift
├── Domain/
│   ├── Entity/
│   │   └── <EntityName>.swift
│   ├── UseCase/
│   │   ├── <UseCaseName>UseCase.swift
│   │   └── <DomainName>UseCaseDependencies.swift
│   └── Interface/
│       └── <DomainName>RepositoryProtocol.swift
├── Data/
│   ├── Repository/
│   │   └── <DomainName>Repository.swift
│   └── Network/
│       ├── Core/
│       │   ├── NetworkService.swift
│       │   └── BaseResponseDTO.swift
│       ├── Error/
│       │   └── DataError.swift
│       └── <DomainName>/
│           ├── <DomainName>Router.swift
│           ├── <DomainName>RequestDTO.swift
│           └── <DomainName>ResponseDTO.swift
├── Core/
│   ├── DesignSystem/
│   └── Extension/
└── Resource/
    ├── Assets.xcassets
    └── Info.plist
```

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

TCA `State` 내부 프로퍼티가 많아질 때는 성격이 비슷한 상태끼리 모아 배치한다.
예를 들어 navigation, 화면 표시 상태, 필터/입력 상태, 지도 SDK 연동 상태처럼 역할 단위로 묶고, 그룹 사이에는 빈 줄을 둔다.
프로퍼티를 단순 추가 순서로 계속 나열하지 않는다.

#### SwiftUI View 구성

SwiftUI View는 `body`가 화면의 큰 레이아웃 구조를 먼저 보여주도록 구성한다.
`body` 안에 모든 세부 modifier를 직접 길게 나열하기보다, 의미 있는 UI 덩어리에 이름을 붙여 `private var` 또는 작은 `View`로 분리한다.

분리 기준:

- 여러 요소가 합쳐져 하나의 UI 의미를 만들면 묶는다.
- Stack이 중첩되어 레이아웃 의도를 다시 해석해야 하면 이름을 붙인다.
- overlay, alignment, gesture처럼 동작 의도가 있는 레이아웃은 의도가 드러나는 이름으로 감싼다.
- 단순한 `Text` 한 줄처럼 독립 의미가 약한 요소를 과하게 쪼개지 않는다.
- 여러 화면에서 재사용되거나 상태/로직이 생기면 별도 `View` 타입 또는 파일로 분리한다.

예:

```swift
var body: some View {
    VStack(alignment: .leading, spacing: 0) {
        thumbnailWithLikeButton
        listingInfo
    }
}

private var thumbnailWithLikeButton: some View {
    ZStack(alignment: .topTrailing) {
        thumbnailImage
        likeButton
    }
}

private var listingInfo: some View {
    VStack(alignment: .leading, spacing: 0) {
        priceText
        additionalInfoText
        tagRow
    }
}
```

목적은 View를 작게 쪼개는 것이 아니라, 레이아웃 의도를 코드에서 바로 읽히게 하는 것이다.

### Navigation

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

### Global Popup

전역 팝업은 `RootFeature`와 `RootView`에서 관리한다.

UIKit처럼 각 화면에서 현재 ViewController를 찾아 `present`하지 않는다.
SwiftUI + TCA에서는 팝업 표시 여부와 내용을 `RootFeature.State`에 상태로 두고, `RootView`가 그 상태를 보고 화면 최상단에 팝업 오버레이를 그린다.

팝업은 성격에 따라 구분해서 사용한다.

- `notice`: 사용자에게 정보를 알리고 `확인` 버튼으로 닫는 팝업. 별도 기능 동작 없이 dismiss만 필요할 때 사용한다.
- `action`: 사용자의 확인이 필요한 동작 팝업. 예: 로그아웃, 회원 탈퇴. 취소 버튼은 dismiss만 하고, 주요 버튼은 해당 feature의 실제 동작으로 이어진다.

사용 규칙:

- 하위 feature는 전역 팝업을 직접 그리거나 UIKit presentation을 호출하지 않는다.
- 하위 feature는 `AppPopup`을 완성한 뒤 delegate 성격의 action으로 Root에 팝업 표시를 요청한다.
- feature 문맥별 팝업 문구와 `notice` / `action` 선택은 해당 feature가 결정한다.
- 네트워크 또는 비즈니스 에러를 사용자 메시지로 바꾸는 작업도 해당 feature가 담당한다. 서버 에러 코드별 문구 분기가 필요하면 Root가 아니라 feature 또는 feature 전용 mapper/helper에 둔다.
- Root는 팝업 표시 상태와 전역 오버레이만 담당하며, feature별 에러 코드나 문구를 해석하지 않는다.
- `notice` 팝업의 확인 버튼은 Root에서 dismiss한다.
- `action` 팝업의 실제 비즈니스 동작은 해당 feature에서 처리한다. Root는 주요 버튼 탭을 해당 feature action으로 전달하는 역할만 한다.
- `action` 팝업을 요청하는 feature는 주요 버튼 이후 실행될 확정 action을 별도로 가진다. 예: 로그아웃 팝업을 요청한 feature는 `logoutConfirmed`, 탈퇴 팝업을 요청한 feature는 `deleteAccountConfirmed` 같은 action에서 실제 동작을 처리한다.
- 입력, 선택, 다중 버튼처럼 `notice` / `action`으로 표현하기 어려운 팝업 요구사항이 생기면 임의로 새 타입을 만들지 않고 먼저 확인한다.

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

UI 프레임워크나 외부 데이터 소스(Alamofire, Keychain 등)에 의존하지 않는 순수 비즈니스 로직을 담당한다.

구성:
- `Entity`: 서비스의 순수 비즈니스 모델 구조체. 서버 DTO의 규격에 종속되지 않고 화면 및 로직에 필요한 형태로 정의한다.
- `UseCase`: 단일 책임 원칙(SRP)에 따라 하나의 비즈니스 흐름당 하나의 파일로 구현하는 것을 지향한다. 인터페이스와 구현체를 포함하며, TCA Dependency 시스템에 등록하여 사용한다.
- `Interface`:  데이터 레이어의 고립 및 의존성 역전(DIP)을 위해 Repository 프로토콜을 이 계층에 선언한다.

### Data

외부 데이터 소스 및 네트워크 통신을 처리하고, 서버 원시 데이터를 도메인 엔티티로 변환하는 계층이다.

구성:
- `Repository`: Data/Repository에 위치하며, DTO 검증, 도메인 에러 매핑, Entity 변환을 전담한다.
- `Network/Core`: 네트워크 서비스 인프라 및 전역 공통 응답 규격을 관리한다.
- `Network/도메인별 폴더`: Router(URLRequestConvertible), RequestDTO, ResponseDTO 규격을 명확히 분리하여 캡슐화한다.

### Resource

앱 리소스를 관리한다.

예:
- Assets
- xcconfig
- Info.plist

### Localization

- `Domain/Entity/User/AppLanguage.swift`는 지원 언어와 서버 API 코드, Locale 식별자만 표현한다.
- 시스템 Locale을 앱 언어로 변환하는 책임은 `Core/Localization/AppLanguageResolver.swift`에 둔다.
- String Catalog 리소스와 문자열 Key를 실제 `String`으로 해석하는 책임은
  `Core/Localization/AppLocalizer.swift`에 둔다.
- Feature State의 기본 언어는 결정적인 값인 영어를 사용하고, 시스템 언어 및 저장 언어 선택은
  Root lifecycle에서 한 번만 수행한다.
- 서버 API 코드와 Apple Locale 식별자는 동일하다고 가정하지 않고 `apiCode`와
  `localeIdentifier`로 구분한다.

## Network & API 연동 가이드라인
### 공통 응답 포맷 (Common Wrapper) 처리
서버의 모든 응답(성공/실패)은 전역 공통 구조를 따르므로, BaseResponseDTO를 통해 1차 파싱을 수행한다. 실패 응답 시 클라이언트는 HTTP 상태 코드뿐만 아니라 error.code 문자열을 기반으로 비즈니스 분기를 처리해야 한다.

### NetworkService의 책임 및 인터셉터(Interceptor)
NetworkService는 Alamofire Session을 관리하며 아래 규격을 준수한다.
- 제네릭 디코딩: 응답 성공 시 BaseResponseDTO.data를 언래핑하여 리턴한다.
- 서버 공통 에러 변환: success가 false이거나 에러 객체가 포함된 경우, error.code를 추출하여 DataError.serverError(code:message:)를 상위 레이어로 던진다.

## Scope Rule

단순 UI 또는 디자인 시스템 작업에는 Domain/Data 계층을 억지로 만들지 않는다.
기능 요구사항이 비즈니스 로직, 외부 데이터, 저장소 의존성을 가질 때 필요한 계층을 추가한다.
