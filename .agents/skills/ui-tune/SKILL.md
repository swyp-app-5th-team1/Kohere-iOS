---
name: ui-tune
description: Use when tuning Kohere SwiftUI UI from user-provided Figma values, checking previews or simulator-rendered screens, mapping values to existing app tokens/assets/helpers, or fixing visual breakage without inventing design values.
---

# UI Tune

## Purpose

Kohere의 SwiftUI UI를 사용자가 제공한 Figma 기준값에 맞춰 조정하고, 필요한 경우 `ios-simulator-browser`로 Preview 또는 Simulator 화면을 확인한다.

## Source Of Truth

1. 사용자가 자연어로 제공한 Figma 수치, 컬러, 타이포, 의도
2. 앱 내부 design token, color asset, typography helper
3. 기존 동일 패턴 화면의 구현
4. `docs/design-system.md`는 필요할 때만 보조 참고

Figma MCP나 문서에서 임의로 값을 추측하지 않는다. 기준값이 부족하면 질문한다.

## Hard Rules

- spacing, padding, radius, color, typography 값을 주관적으로 창작하지 않는다.
- "좁아 보임", "답답해 보임" 같은 감각만으로 수치를 바꾸지 않는다.
- 하드코딩 값이 기존 token/asset/helper와 같은 의도라면 기존 앱 리소스로 치환한다.
- Figma 값이 주어졌는데 코드 값이 다르면 제공된 값에 맞춘다.
- 제공된 값으로 화면이 깨지거나 trade-off가 생기면 사용자에게 장단점과 추천안을 먼저 묻는다.

## Workflow

1. 대상 화면과 사용자가 제공한 디자인 기준값을 정리한다.
2. 기존 코드에서 token, asset, helper, 동일 패턴 화면을 확인한다.
3. 기준값이 충분하면 최소 범위로 UI를 수정한다.
4. 가능하면 `ios-simulator-browser`로 화면을 확인한다.
5. 값이 부족하거나 디자인 방향 결정이 필요하면 질문한다.
6. 마지막에 변경/확인, 검증, 미검증을 짧게 보고한다.

## Ask Before

- Figma 값이 없는 spacing, radius, color, typography를 새로 정해야 할 때
- 디자인 시스템에 없는 새 token 또는 asset이 필요할 때
- 화면 구조, 정보 배치, 컴포넌트 종류를 바꿔야 할 때
- 제공된 수치 적용 시 화면이 깨져 다른 수치를 쓰고 싶을 때
- 성능, 구현 복잡도, 디자인 일관성 사이 trade-off가 생길 때

## Related Skills

- `$design-system`: 앱 내부 디자인 토큰, 색상, 타이포 기준을 확인할 때
- `$ios-simulator-browser`: Preview 또는 Simulator 화면을 Codex in-app browser에서 보며 확인할 때
- `$flow-check`: UI 수정 후 실제 탭, 네비게이션, 상태 변화까지 검증할 때

## Report Shape

```text
변경/확인:
- ...

검증:
- Preview/Simulator 확인: 성공/실패/미실행
- 빌드: 성공/실패/미실행

미검증:
- ...
```
