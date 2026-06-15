# Design System

이 문서는 Figma 디자인 시스템을 iOS 코드에 옮길 때의 구조 규칙을 정리한다.
구체적인 토큰 값은 Figma 기준이 확정되거나 구현 단계에서 확인한 뒤 반영한다.

## Color

색상은 Asset Catalog의 Color Set으로 관리한다.

- Palette Color는 Figma의 원시 색상 이름과 값을 보존하기 위한 색상이다.
- Semantic Color는 실제 UI 역할 기준으로 사용하는 색상이다.
- 초기에는 Palette와 Semantic의 hex 값 중복을 허용한다.
- SwiftUI에서는 `Color.Kohere.<colorName>` 형태의 extension으로 접근한다.
- 현재는 Light/Dark 값을 분리하지 않고 Any Appearance 기준으로 정의한다.
- 다크모드 대응이 필요해지면 Semantic Color Set부터 Light/Dark 값을 확장한다.

## Typography

Typography는 Figma 텍스트 스타일을 기준으로 하나의 스타일 단위로 관리한다.

- 각 스타일은 font family, size, weight, line height, letter spacing을 함께 가진다.
- 스타일 이름은 Figma의 typography 이름을 최대한 보존한다.
- SwiftUI에서는 `KohereTextStyle`과 View modifier를 통해 typography 스타일을 적용한다.
- 예상 사용 형태는 `Text("Title").kohereTextStyle(.heading1Bold)`이다.
- Figma의 line height와 SwiftUI의 line spacing은 1:1 개념이 아니므로 구현 후 실제 화면에서 보정한다.

## Spacing and Grid

Spacing과 Grid는 1차 디자인 시스템 범위에서 보류한다.

- Figma의 grid와 간격 정보는 구현 시 참고 자료로만 사용한다.
- 현재 단계에서는 별도의 `KohereSpacing` 또는 grid abstraction을 만들지 않는다.
- 개발 중 반복되는 간격 값이 많아지거나 화면 간 일관성이 깨질 조짐이 보이면 시스템화 필요성을 사용자에게 제안한다.
- 시스템화가 필요하다고 판단되면 구현 전에 범위와 네이밍을 먼저 논의한다.

## Elevation

Elevation과 Shadow는 추후 구체화한다.

- Figma에는 `shadow-normal-*`, `shadow-spread-*` 계열의 shadow token이 있다.
- SwiftUI 기본 `.shadow`는 Figma/CSS의 spread 값을 직접 지원하지 않는다.
- shadow를 시스템화할 때는 Figma token 이름을 보존할지, spread를 어떻게 근사 또는 구현할지 먼저 논의한다.
- 당장 구현 범위에는 포함하지 않는다.
