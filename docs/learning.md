# Learning

이 문서는 Kohere 구현 과정에서 학습하면 좋은 CS/iOS 개념과 참고 주제를 기록한다.

## Purpose

- 구현 중 마주친 개념을 그냥 넘기지 않고 학습 주제로 남긴다.
- 취업 준비에 도움이 되는 CS, iOS, 아키텍처, 테스트 관점을 정리한다.
- 프로젝트 규칙과 개인 학습 메모를 분리한다.

## Rules

- 프로젝트 구현에 실제로 연결되는 주제를 우선 기록한다.
- 단순 링크 모음이 아니라, 왜 공부해야 하는지와 어느 코드와 관련되는지 함께 적는다.
- 학습 주제가 구현 규칙으로 확정되면 관련 문서로 옮긴다.

## Topics

### SwiftUI View 읽기와 AI 작업물 소유하기

SwiftUI는 UIKit처럼 UI 요소 선언, hierarchy 구성, constraint 배치가 명확히 분리되지 않는다.
`body` 안에서 View 생성, 레이아웃, 스타일 modifier가 함께 선언되기 때문에, 코드리뷰나 복기 시에는 "작은 문법을 전부 외우기"보다 "이 View가 어떤 의미 단위로 구성되는지"를 먼저 잡는다.

#### UIKit + SnapKit과 다른 점

UIKit + SnapKit에서는 보통 다음 흐름으로 화면을 읽는다.

- `UILabel`, `UIImageView`, `UIButton` 같은 UI 요소를 프로퍼티로 선언한다.
- `configureHierarchy()`에서 subview 관계를 만든다.
- `configureLayout()`에서 SnapKit constraint를 한곳에 모아 배치한다.
- `configureStyle()` 또는 `configure()`에서 색상, 폰트, 상태를 입힌다.

SwiftUI에서는 이 분리가 기본 형태가 아니다.
`VStack`, `HStack`, `ZStack`, `padding`, `frame`, `foregroundColor` 같은 코드가 한 흐름 안에 섞인다.
따라서 SwiftUI 리뷰에서는 "어디에 선언됐는가"보다 "어떤 의미의 덩어리인가"를 기준으로 읽는다.

#### View 분리 기준

서브뷰화의 목적은 코드를 무조건 작게 쪼개는 것이 아니라, 레이아웃 의도에 이름을 붙이는 것이다.

좋은 분리 기준:

- 여러 요소가 합쳐져 하나의 UI 의미를 만들면 묶는다.
- Stack이 2단계 이상 중첩되어 의도를 다시 해석해야 하면 이름을 붙인다.
- alignment, overlay, gesture처럼 동작 의도가 있는 레이아웃은 private computed view로 감싼다.
- 여러 화면에서 재사용되거나 상태/로직이 생기면 별도 `View` 타입 또는 파일로 분리한다.

과한 분리 기준:

- 단순한 `Text` 한 줄을 모두 `priceText`, `usdPriceText`, `locationText`처럼 따로 빼면 오히려 읽는 흐름이 끊길 수 있다.
- 같은 정보 영역에 속한 텍스트들은 개별 요소보다 하나의 의미 단위로 보는 편이 좋다.

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
        Text(item.formattedPrice)
        Text(item.formattedUsdPrice)
        Text(item.detailsDescription)
        Text(item.locationDescription)
        tagRow
    }
}
```

이 구조에서 `thumbnailWithLikeButton`은 "이미지 오른쪽 위에 좋아요 버튼을 overlay한다"는 의도를 드러낸다.
`listingInfo`는 가격, 부가 가격, 상세 정보, 위치, 태그가 합쳐진 "매물 정보 영역"이라는 의미를 드러낸다.

#### body를 레이아웃 지도처럼 쓰기

SwiftUI에서 UIKit의 `configureLayout()`에 가장 가까운 읽기 방식은 `body`를 화면의 큰 구조만 보여주는 "레이아웃 지도"로 만드는 것이다.

예:

```swift
var body: some View {
    HStack(alignment: .top, spacing: 24) {
        thumbnailImage
        listingInfo
        Spacer()
        likeButton
    }
}
```

이렇게 하면 코드리뷰 시 먼저 "이미지, 정보, 여백, 좋아요 버튼으로 구성된 카드"라는 구조를 읽고, 세부 스타일은 필요한 부분만 내려가서 확인할 수 있다.

#### AI와 함께 구현할 때의 건강한 역할 분담

AI가 완성 코드를 한 번에 제시하면 작업 속도는 빨라지지만, 구현 의도와 구조가 내 기억에 얕게 남을 수 있다.
따라서 모든 코드를 손으로 다시 짤 필요는 없지만, 다음 부분은 직접 손으로 작성하거나 최소한 코드 없이 다시 설명할 수 있어야 한다.

- SwiftUI 화면의 큰 레이아웃 구조
- TCA `State`, `Action`, reducer 흐름
- API response, DTO, Entity, ViewState의 변환 관계
- 사용자 입력이 상태를 바꾸고 화면에 반영되는 흐름
- navigation 연결과 화면 전환 책임
- 내부 API 메서드의 역할과 호출 순서

AI에게 맡기기 좋은 부분:

- 반복적인 modifier 정리
- 디자인 시스템 토큰 적용
- boilerplate 초안
- 네이밍 후보
- 테스트 케이스 초안
- 이미 이해한 구조의 조립과 정리

기준은 "AI가 만든 코드를 내가 승인했는가"가 아니라 "내가 내일 직접 수정할 수 있는가"이다.
핵심 구조는 직접 손으로 잡고, 반복적인 조립과 정리는 AI를 활용하는 방식이 가장 건강하다.
