# Planning

이 문서는 Kohere의 기능 계획, 작업 분해, 미확정 요구사항을 기록한다.

## Purpose

- 구현 전에 요구사항을 구체화한다.
- 미확정 기획을 확정된 요구사항처럼 구현하지 않도록 관리한다.
- 기능을 작은 작업 단위로 나누고 우선순위를 정한다.

## Planning Rules

- 애매한 요구사항은 구현 전에 질문으로 남긴다.
- 선택지가 여러 개라면 장단점과 추천안을 함께 기록한다.
- 확정된 결정은 `docs/progress.md`의 Decisions로 옮긴다.
- 오래되었거나 폐기된 계획은 정리한다.

## Feature Candidates

- 탭별 실제 첫 화면 구현.
- 첫 push depth 화면을 구현하면서 TCA `StackState` destination case 예시 작성.

## Open Questions

- 각 탭 루트 화면의 실제 UI와 초기 데이터 요구사항.
- 첫 상세 화면에서 destination State에 어떤 데이터만 넘길지에 대한 기준.

## Backlog

- 딥링크, 푸시 알림, 로그인 전환 등 전역 이동 정책이 필요해질 때 Root/Flow navigation 정책 확장.
