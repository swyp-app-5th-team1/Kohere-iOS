---
name: review
description: Use when reviewing Kohere iOS changes for correctness, regressions, architecture drift, missing tests, design-system issues, or maintainability risks.
---

# Review

## Purpose

Kohere의 iOS 변경사항을 리뷰할 때 사용한다.

## Context

- 먼저 `AGENTS.md`를 확인한다.
- 관련 기준 문서가 있으면 `docs/*.md`를 함께 확인한다.
- 리뷰는 취향보다 버그, 회귀, 테스트 공백, 유지보수 리스크를 우선한다.

## Workflow

1. 변경 diff와 주변 코드를 함께 확인한다.
2. 실제 동작 위험, 아키텍처 이탈, 디자인 시스템 위반, 테스트 누락을 찾는다.
3. 문제가 있으면 파일과 라인을 근거로 설명한다.
4. 문제가 없으면 남은 검증 공백이나 확인하지 못한 리스크를 말한다.
5. 마지막에 짧은 요약을 남긴다.
