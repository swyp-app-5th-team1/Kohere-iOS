# Design System

이 문서는 Figma 디자인 시스템을 iOS 코드에 옮길 때의 구조 규칙을 정리한다.
구체적인 토큰 값은 문서에 전체 목록으로 복사하지 않고, 프로젝트 안의 리소스와 코드에서 관리한다.

## Source Rule

- Figma 화면, 토큰 표, 디자이너가 전달한 명시값만 디자인 시스템의 기준으로 사용한다.
- 스크린샷이나 토큰 표에 없는 값을 개발자가 임의로 추정해서 넣지 않는다.
- 필요한 값이 없거나 reference가 비어 있으면 구현하지 않고 사용자에게 요청한다.
- 실제 색상값, 폰트 수치, shadow 값은 구현 시점에 프로젝트 파일에서 확인한다.
- 문서는 source of truth가 아니라 구조, 네이밍, 판단 기준을 기록하는 용도로 둔다.

## Code Structure

디자인 시스템 코드는 `docs/architecture.md`의 `Core/DesignSystem` 기준을 따른다.

- 타이포그래피, shadow 등 코드 기반 디자인 시스템 API는 `Core/DesignSystem`에 둔다.
- 색상은 Asset Catalog의 Color Set 이름을 SwiftUI generated asset symbol로 직접 사용한다.
- 디자인 시스템 extension은 일반 extension으로 보지 않고 `Core/DesignSystem` 안에 둔다.
- SwiftUI 색상 접근은 타입 추론이 가능한 modifier와 디자인 시스템 API 안에서 `.<assetName>` 형태를 우선한다.
  예: `.foregroundStyle(.labelNormal)`, `kohereSurface(background: .backgroundElevatedNormal, ...)`.
- SwiftUI 타이포그래피 적용 형태는 `Text("Title").kohereTextStyle(.heading1Bold)`를 기준으로 한다.
- 단순 UI 또는 디자인 시스템 작업만으로 Domain/Data 계층을 만들지 않는다.

## Color

색상은 Asset Catalog의 Color Set으로 관리한다.

- Palette Color는 Figma의 원시 색상 이름과 값을 보존하기 위한 색상이다.
- Semantic Color는 실제 UI 역할 기준으로 사용하는 색상이다.
- Color Set 이름은 코드 접근성을 위해 Figma 접두어를 제거한 lowerCamelCase를 사용한다.
- Palette Color는 `primary50`, `coolNeutral90`처럼 계열과 단계만 남긴다.
- Semantic Color는 `primaryNormal`, `labelAlternative`, `backgroundNormalNormal`처럼 역할 이름을 사용한다.
- 초기에는 Palette와 Semantic의 hex 값 중복을 허용한다.
- 현재는 Light/Dark 값을 분리하지 않고 Any Appearance 기준으로 정의한다.
- 다크모드 대응이 필요해지면 Semantic Color Set부터 Light/Dark 값을 확장한다.
- 컬러 작업 시 `Assets.xcassets`의 Color Set과 `Core/DesignSystem`의 Swift 접근 API를 먼저 확인한다.
- `color-global-*` 토큰은 현재 Figma Palette/Token 화면의 구현 대상이 아니므로 제외한다.
- Semantic Color는 Figma reference가 명시된 값과 사용자가 별도로 제공한 확정값만 구현한다.

## Typography

Typography는 Figma 텍스트 스타일을 기준으로 하나의 스타일 단위로 관리한다.

- 기본 글꼴은 Pretendard JP를 사용한다.
- 한국어, 영어, 일본어를 지원하는 Pretendard JP를 기준으로 한다.
- 각 스타일은 font family, size, weight, line height, letter spacing을 함께 가진다.
- 스타일 이름은 Figma의 typography token 이름을 최대한 보존한다.
- Figma의 line height와 SwiftUI의 line spacing은 1:1 개념이 아니므로 구현 후 실제 화면에서 보정한다.
- typography 작업 시 `Core/DesignSystem`의 text style 정의를 먼저 확인한다.

## Spacing and Grid

Spacing과 Grid는 1차 디자인 시스템 범위에서 보류한다.

- Figma의 grid와 간격 정보는 구현 시 참고 자료로만 사용한다.
- 현재 단계에서는 별도의 `KohereSpacing` 또는 grid abstraction을 만들지 않는다.
- 개발 중 반복되는 간격 값이 많아지거나 화면 간 일관성이 깨질 조짐이 보이면 시스템화 필요성을 사용자에게 제안한다.
- 시스템화가 필요하다고 판단되면 구현 전에 범위와 네이밍을 먼저 논의한다.

## Elevation

Elevation과 Shadow는 Figma token 이름을 기준으로 관리한다.

- Figma에는 `shadow-normal-*`, `shadow-spread-*` 계열의 shadow token이 있다.
- SwiftUI 기본 `.shadow`는 Figma/CSS의 spread 값을 직접 지원하지 않는다.
- shadow token 하나가 여러 shadow layer를 가질 수 있으므로 layer 배열로 관리한다.
- shadow의 x, y, blur, spread, color, opacity 값은 Figma/CSS 값을 보존한다.
- spread 재현을 위해 shadow용 shape를 별도로 그리며, 지원 shape는 `rectangle`, `roundedRectangle`, `circle`, `capsule`을 기준으로 한다.
- 일반 surface UI는 배경, clip, shadow 순서가 흐트러지지 않도록 `kohereSurface(background:shape:elevation:)`를 우선 사용한다.
- 이미 모양과 배경이 확정된 UI는 `kohereElevation(_:shape:)`로 shadow만 적용할 수 있다.
- shadow 작업 시 `Core/DesignSystem`의 elevation 정의를 먼저 확인한다.

사용 예시:

```swift
VStack(alignment: .leading, spacing: 8) {
    Text("Title")
        .kohereTextStyle(.heading2Semibold)
    Text("Description")
        .kohereTextStyle(.body2Regular)
}
.padding(16)
.kohereSurface(
    background: .backgroundElevatedNormal,
    shape: .roundedRectangle(cornerRadius: 16),
    elevation: .normalSmall
)
```

```swift
Circle()
    .fill(.backgroundElevatedNormal)
    .frame(width: 56, height: 56)
    .kohereElevation(.normalSmall, shape: .circle)
```
