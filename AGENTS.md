# Kohere Agent Guide

## Product Overview
Kohere is an iOS housing curation app for foreigners who need help finding suitable housing in Korea without understanding Korean real estate terms.

## Working Rules
- 문서 본문과 작업 설명은 한국어로 작성한다.
- 파일명, 디렉토리명, 스킬명, 코드 식별자는 영어를 사용한다.
- 애매한 요구사항은 넘겨짚어 구현하지 말고 먼저 질문한다.
- 개발 선택지가 여러 개라면 장단점을 먼저 설명하고 사용자가 고를 수 있게 한다.
- 새 구조나 파일을 만들기 전에는 목적과 유지보수 비용을 짧게 설명한다.
- 중요한 코드 흐름, 구현 판단, 생략된 맥락을 건너뛰지 않는다.

## Documents
- `docs/design-system.md`: Figma 디자인 시스템을 iOS 코드 구조로 옮기는 기준.
- `docs/architecture.md`: SwiftUI + TCA 기반 레이어 구조와 코드 배치 기준. 세부 기준은 진행하며 보완.
- `docs/progress.md`: 현재 상태, 결정 사항, 최근 작업 로그.
- `docs/planning.md`: 기능 계획, 작업 분해, 미확정 요구사항.
- `docs/learning.md`: 구현 과정에서 학습할 CS/iOS 개념과 참고 주제.

## Skills
- 기획 구체화와 작업 분해는 `$planning`을 사용한다.
- 디자인 시스템 작업은 `$design-system`을 사용한다.
- 기능 구현 작업은 `$feature`를 사용한다.
- 변경사항 리뷰는 `$review`를 사용한다.
- 사용자가 제공한 Figma 기준값으로 UI를 조정하고 화면 확인이 필요하면 `$ui-tune`을 사용한다.
- SwiftUI 성능 이슈를 코드 리뷰하거나 측정 근거가 필요한 개선을 다룰 때는 `$performance-check`를 사용한다.

## Verification
- 코드 변경 후 가능한 가장 좁은 범위의 빌드, 테스트, Preview 확인을 우선한다.
- 사용자가 명시적으로 요청하지 않는 한 `$build-ios-apps:ios-debugger-agent`와 `$flow-check`를 사용한 Simulator 실행 및 조작 검증은 생략하고, 기능 플로우 테스트는 사용자에게 맡긴다.
- 검증하지 못한 항목은 최종 응답에서 명확히 말한다.

## Commit Message
- 커밋 메시지는 `type: 내용` 형식을 사용한다.
- type 키워드는 영어로 쓰고, 내용은 한국어로 작성한다.

사용 가능한 type:
- `feat`: 새로운 기능 구현
- `fix`: 버그, 오류 해결
- `chore`: 코드 수정, 내부 파일 수정, 애매한 작업 또는 잡일
- `add`: 에셋 추가
- `del`: 쓸모없는 코드 삭제
- `design`: 디자인 관련 수정
- `docs`: README, WIKI, 문서 개정
- `refactor`: 전면 수정 또는 구조 개선
- `setting`: 프로젝트 설정 관련 작업
