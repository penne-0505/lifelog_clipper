---
title: "LifeLog Clipper MVP Plan: UI & Clipboard Flow"
status: proposed
draft_status: n/a
created_at: 2026-01-01
updated_at: 2026-01-02
references:
  - _docs/draft/requirements.md
  - _docs/archives/plan/Core/lifelog-clipper-mvp/plan.md
related_issues: []
related_prs: []
---

## Overview
直近7日の一覧表示とコピー導線を持つ単一画面UI、およびマイクロインタラクションを実装する。

## Scope
- 起動時の自動ロードと状態表示
- 直近7日リストの表示（今日→過去の降順）
- 各日のコピー導線と処理中状態
- 成功/失敗通知（トースト等）

## Non-Goals
- 複数画面構成
- 解析・可視化UI

## Requirements
- **Functional**:
  - 起動時に読み込みを開始し、状態を表示する
  - 日別行のコピー押下でJSON生成とクリップボード格納を行う
  - Health Connect利用不可/権限未許可の表示を行う
- **Non-Functional**:
  - 状態が視覚的に判別できるマイクロインタラクションを実装する

## Tasks
- 直近7日リストUIを実装
- ローディング/コピー中の状態表示を実装
- クリップボードコピー処理を実装
- 成功/失敗通知を実装

## Test Plan
- 起動時の自動ロードと状態表示が機能する
- コピー押下でクリップボードにJSONが格納される
- 処理中/成功/失敗の状態が視覚的に判別できる

## Deployment / Rollout
- 実機でUI状態遷移とコピー導線を確認
