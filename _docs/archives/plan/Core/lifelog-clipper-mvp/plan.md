---
title: "LifeLog Clipper MVP Plan (Index)"
status: proposed
draft_status: n/a
created_at: 2026-01-01
updated_at: 2026-01-02
references:
  - _docs/draft/requirements.md
related_issues: []
related_prs: []
---

## Overview
LifeLog Clipper MVPの実装計画を、実装領域ごとのサブプランに分割して管理する。

## Scope
- Health Connectの利用可否判定・権限要求フロー
- 直近7日分のデータ取得、日別window分割、JSON生成
- クリップボードコピーを中心とした単一画面UI

## Non-Goals
- サーバー提供や外部連携（クラウド同期など）
- 30日超の長期履歴保持
- 解析・可視化（チャート、統計ダッシュボード）
- iOS対応

## Requirements
- **Functional**:
  - 直近7日分の日別ログをJSONとしてコピーできる
  - Health Connectの利用可否と権限状況に応じたUIを提供する
  - JSONは固定フィールド順で生成される
- **Non-Functional**:
  - 生成JSON本文はログに出力しない
  - INTERNET権限を付与しない（実機検証で影響を確認）

## Plan Structure
- `_docs/archives/plan/Core/lifelog-clipper-mvp/health-connect-integration.md`
  - 利用可否判定、権限フロー、Android固有設定
- `_docs/archives/plan/Core/lifelog-clipper-mvp/data-aggregation-json.md`
  - 取得・集計・JSONスキーマ・null方針・フィールド順固定
- `_docs/archives/plan/Core/lifelog-clipper-mvp/ui-clipboard-flow.md`
  - 直近7日リスト、ローディング/コピー状態、通知UI

## Test Plan
- サブプランに定義された観点を統合して実機検証する
- Health Connect利用可否/権限/データ取得/JSON生成/コピー導線を一通り確認する

## Deployment / Rollout
- ローカル実機に対してデバッグビルドで検証
- 早期MVP段階は限定配布（APK）を想定
- ロールバックは前ビルドの再インストールで代替

## Risks / Open Questions
- healthパッケージがINTERNET権限無しで動作するか実機で確認が必要
- Health Connect未対応端末での判定ロジックとreason分類の実機検証が必要
- 睡眠ステージ取得が端末/OS依存で欠損する可能性がある
