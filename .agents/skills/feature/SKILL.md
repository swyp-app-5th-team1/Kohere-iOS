---
name: feature
description: Use when implementing or planning a Kohere iOS feature, screen, flow, state change, navigation path, API integration, or user-facing behavior.
---

# Feature

## Purpose

Kohere의 iOS 기능 구현 또는 기능 설계를 진행할 때 사용한다.

## Context

- 먼저 `AGENTS.md`를 확인한다.
- 아키텍처 기준은 `docs/architecture.md`를 확인한다.
- 현재 진행 상태와 미결정 사항은 `docs/progress.md`를 확인한다.

## Workflow

1. 요구사항을 화면, 상태, 데이터, 네비게이션, 검증 기준으로 나눈다.
2. 애매한 동작이나 개발 선택지가 있으면 구현 전에 질문한다.
3. 기존 코드 패턴을 확인하고 가장 작은 변경 단위로 진행한다.
4. 필요한 경우 테스트 가능성과 유지보수 비용을 함께 설명한다.
5. 검증한 항목과 검증하지 못한 항목을 마지막에 정리한다.
