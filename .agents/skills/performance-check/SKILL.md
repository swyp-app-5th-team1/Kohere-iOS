---
name: performance-check
description: Use when reviewing Kohere SwiftUI performance, diagnosing janky scrolling, slow screen entry, excessive re-rendering, memory or CPU concerns, or preparing measured before/after engineering trade-off notes.
---

# Performance Check

## Purpose

Kohere SwiftUI 화면의 잠재 성능 이슈를 기본적으로 코드 리뷰 중심으로 점검한다. 실제 느림, 끊김, 메모리 증가가 있거나 사용자가 요청하면 profiling 또는 ETTrace 기반 측정으로 확장한다.

## Default Mode

먼저 코드만 보고 낮은 비용으로 점검한다.

- 불필요한 View 재계산 가능성
- 무거운 computed property
- 불안정한 `ForEach` identity
- 반복 호출되는 `onAppear` 또는 task
- 이미지 로딩, 리사이징, 캐싱 문제
- `List`, `LazyVStack`, 큰 View 구조 문제
- 너무 넓은 state 소유로 인한 과도한 업데이트

## Measuring Mode

아래 중 하나에 해당하면 사용자에게 확인한 뒤 측정을 제안한다.

- 스크롤 끊김, 화면 진입 속도, 이미지 로딩, API 이후 렌더링 지연처럼 설명할 만한 개선
- 코드 리뷰만으로 원인을 확정하기 어려운 성능 문제
- before/after 수치가 필요한 개선
- 사용자가 profiling, ETTrace, Instruments 성격의 검증을 명시한 경우

측정 시 동일 데이터, 동일 시나리오, 동일 시간 범위로 before/after를 비교한다. Simulator 결과와 실제 기기 결과의 한계를 구분한다.

## Notes Policy

기본적으로 repo 문서에 기록하지 않는다. 중요한 성능 개선, 구조 선택, UX trade-off, 측정 결과를 개인 기록으로 남기려면 `docs/private/engineering-notes.md`를 사용한다.

`docs/private/engineering-notes.md`가 이미 있으면 사용자에게 다시 묻지 않고 기록한다. 파일이나 폴더가 없으면 새로 만들어 기록할지 먼저 질문한다.

기록 템플릿:

```markdown
## 제목

- 날짜:
- 맥락:
- 문제:
- 선택지:
- 결정:
- 이유:
- 측정 환경:
- 측정 방법:
- Before:
- 변경 내용:
- After:
- 개선 수치:
- 한계:
- 직접 재현 방법:
- 면접에서 설명할 포인트:
```

## Ask Before

- 실제 profiling 또는 ETTrace를 실행할지
- 어떤 시나리오를 before/after 측정 기준으로 삼을지
- 성능 개선을 위해 코드 복잡도를 높일지
- UI 품질, 기능 동작, 유지보수성을 희생할 가능성이 있을 때
- 개인 기록 또는 팀 공유 문서에 남길지

## Related Skills

- `$swiftui-performance-audit`: SwiftUI 성능 리뷰를 더 깊게 볼 때
- `$ios-ettrace-performance`: Simulator ETTrace profiling이 필요할 때
- `$ios-debugger-agent`: 성능 이슈를 실제 플로우에서 재현해야 할 때
- `$flow-check`: 성능 변경 후 기능 플로우가 깨지지 않았는지 확인할 때

## Report Shape

```text
변경/확인:
- ...

검증:
- 코드 성능 리뷰: 완료/미실행
- Profiling/ETTrace: 성공/실패/미실행
- Before/After 측정: 완료/미실행

미검증:
- ...
```
