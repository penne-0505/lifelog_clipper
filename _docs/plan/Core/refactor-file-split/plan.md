---
title: Split Core Logic into Modules
status: proposed
draft_status: n/a
created_at: 2026-01-02
updated_at: 2026-01-02
references: []
related_issues: []
related_prs: []
---

## Overview
単一ファイルに集約されたUI/状態管理/Health Connect制御/データ集計ロジックを、責務ごとに分割し保守性と拡張性を高める。

## Scope
- `lib/main.dart` をアプリのエントリとルート構成に専念させる
- Health Connect 周辺の状態/権限管理を専用モジュールへ分離
- UIコンポーネント（ページ、ウィジェット）を分離
- データ集計/モデル/日時ユーティリティの分割
- 既存の挙動とUIを維持する（外部仕様の変更なし）

## Non-Goals
- 新機能追加やUIデザインの刷新
- Health Connect の取得ロジック・集計仕様の変更
- 依存パッケージの入れ替え

## Requirements
- **Functional**: 既存の表示/権限フロー/データ取得が同等に動作すること
- **Non-Functional**: ファイル分割後もLintエラーがなく、責務単位で再利用しやすい構成であること

## Tasks
1. `lib/main.dart` からアプリ初期化とルートウィジェット以外のクラスを分離
2. Health Connect制御: 状態/権限/判定ロジックを `lib/health_connect/` 配下へ切り出し
3. UI: `HealthConnectGatePage` およびサブUIを `lib/ui/`（または `lib/features/`）へ分割
4. 集計: `lib/lifelog/data_aggregation.dart` をモデル/集計/ユーティリティに分割
5. 参照関係を整理し、循環参照がないことを確認
6. 必要に応じてドキュメント/コメントを補記

## Test Plan
- `flutter run` で起動し、以下を確認
  - Health Connect未許可/未利用時の表示とボタン動作
  - 権限許可後に直近7日分の一覧が表示される
  - コピー操作でSnackBarが表示される

## Deployment / Rollout
- 既存アプリ内のリファクタリングのみ。追加のデプロイ手順なし
