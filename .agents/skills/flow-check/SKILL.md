---
name: flow-check
description: Use when verifying Kohere app behavior on an iOS Simulator, including taps, navigation depth, push or sheet presentation, state changes, logs, crashes, and feature flows after implementation.
---

# Flow Check

## Purpose

Kohere 기능 구현 후 실제 Simulator에서 지정한 플로우를 조작해 검증한다. 필요하면 `$build-ios-apps:ios-debugger-agent`를 사용하고, 사용자가 화면을 같이 봐야 하면 `$build-ios-apps:ios-simulator-browser`를 병행한다.

## Required Context

사용자 요청을 자연어로 해석한다. 충분하면 바로 검증하고, 부족하면 코드에서 가능한 플로우를 찾아 짧게 확인 질문을 한다.

필요한 정보:

- 시작 화면 또는 상태
- 수행할 동작
- 기대 결과
- 확인할 로그, 상태, 뒤로가기, 에러 여부

## Workflow

1. 검증할 플로우를 한 문장으로 정리한다.
2. 시작 상태와 기대 결과가 부족하면 질문한다.
3. `$build-ios-apps:ios-debugger-agent`로 앱 빌드, 설치, 실행, 조작, 로그 확인을 진행한다.
4. 화면 확인이 중요하면 `$build-ios-apps:ios-simulator-browser`를 함께 사용한다.
5. 실패하면 먼저 실패 단계, 실제 결과, 기대 결과, 로그를 보고한다.
6. 수정 선택지가 있으면 장단점과 추천안을 제시한다.
7. 명백한 단순 누락은 수정할 수 있지만, 반드시 이유와 변경 내용을 설명하고 재검증한다.

## Fix Policy

자동 수정 가능:

- 버튼 action 연결 누락
- route enum case 누락
- `NavigationStack` path append 누락
- destination 매핑 오타 또는 누락
- 빌드 에러처럼 해석 여지가 낮은 문제

질문 필요:

- push, sheet, fullScreenCover 같은 네비게이션 정책 결정
- 로그인 전 사용자 처리 방식
- 에러 표시 방식(toast, alert 등)
- 새 화면 구조 또는 UX 정책 도입
- 기능 동작 의미가 바뀌는 우회 수정

## Related Skills

- `$build-ios-apps:ios-debugger-agent`: Simulator 빌드, 실행, 조작, 로그 확인
- `$build-ios-apps:ios-simulator-browser`: 사용자가 AI 조작 현황을 화면으로 따라봐야 할 때
- `$feature`: 검증 실패가 새 기능 구현 또는 구조 변경으로 이어질 때
- `$review`: 최종 변경사항 리뷰가 필요할 때

## Report Shape

```text
변경/확인:
- ...

검증:
- 빌드: 성공/실패/미실행
- Simulator 플로우: 성공/실패/미실행
- 로그 에러: 없음/있음/미확인

미검증:
- ...
```
