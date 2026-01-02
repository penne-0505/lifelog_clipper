---
title: "LifeLog Clipper MVP Plan: Data Aggregation & JSON"
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
歩数・心拍・睡眠データの取得、日別window分割、集計、JSON生成（固定順）を実装する。

## Scope
- 直近7日分のデータ取得（Health Connect）
- 日別windowへの分割と集計ロジック
- JSONスキーマ準拠のDTO設計と固定フィールド順の出力
- null方針とavailabilityに応じた出力制御
 - Health Connect未対応型（SLEEP_IN_BED / SLEEP_AWAKE_IN_BED）は取得対象から除外

## Non-Goals
- 30日超の長期履歴取得
- 解析・可視化

## Requirements
- **Functional**:
  - steps.totalは日別合計を出力する
  - heart_rateはmin/max/時間重み付き平均/サンプル数を出力する
  - sleepはセッション終了日（起床日）で日付を決定し、セッションとステージを保持する
  - sleepの集計は日付境界でクリップせず、セッション単位でsummaryを付与する
  - availability.unavailable時は健康データ値をnull方針に従って出力する
- **Non-Functional**:
  - JSONフィールド順序を固定する
  - generated_atはコピー押下時刻（秒精度）を使用する

## Tasks
- 直近7日windowを定義し、日別windowへ分割する処理を実装
- steps/heart_rate/sleepの集計ロジックを実装
- sleepステージの重複除外ロジックを実装
- JSON DTOを設計し、固定順MapでtoJsonを実装
- 取得失敗時のnull方針を反映する
 - Health Connect未対応型を取得対象から除外する

## Test Plan
- 直近7日全日でJSONフィールド順が固定される
- 心拍の時間重み付き平均がサンプル間隔の不均一でも正しく算出される
- 睡眠ステージの重複除外が二重計上されない
- 取得失敗時にnull方針が適用される
- Health Connect未対応型を含む場合でも取得が失敗しないことを確認する
- 夜間〜朝の睡眠セッションが起床日のJSONに含まれることを確認する

## Deployment / Rollout
- 実機で取得結果とJSON出力を確認

## Risks / Open Questions
- sleepステージが取得できない端末でsummaryの扱いをどう検証するか
