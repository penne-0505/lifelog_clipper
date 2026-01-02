---
title: "LifeLog Clipper MVP Plan: Health Connect Integration"
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
Health Connectの利用可否判定と権限要求フロー、Android固有設定を実装する。

## Scope
- Health Connectの利用可否判定とreason分類
- 起動時の権限要求と再試行/設定導線
- Android Manifestのqueries/権限宣言
- Android 14向けのMainActivity設定（FlutterFragmentActivity）
 - Health Connect権限画面のためのintent-filter/queries/activity-alias設定

## Non-Goals
- KotlinのPlatform Channelによる代替実装（healthパッケージで不足が判明した場合のみ検討）
- iOS向けHealth連携

## Requirements
- **Functional**:
  - Health Connectが利用不可の場合は権限要求を行わない
  - 権限未許可時は「権限が必要」と再試行/設定遷移の導線を表示する
  - availability.reasonは規定値（not_installed/disabled/unsupported/unknown）から選択する
- **Non-Functional**:
  - INTERNET権限を付与しない
  - 生成JSON本文はログに出力しない

## Tasks
- Health Connect利用可否判定ロジックの実装
- availability.reason のマッピングを明文化（sdkUnavailableProviderUpdateRequired → disabled、sdkUnavailable かつ SDK < 28 → unsupported、他は not_installed、取得不能は unknown）
- 権限要求フローとUI状態遷移の実装
- 設定画面への遷移導線を実装
- Android Manifestのqueries/権限宣言を更新
- FlutterFragmentActivityの適用確認
 - ACTION_SHOW_PERMISSIONS_RATIONALE の intent-filter / queries / activity-alias を追加

## Test Plan
- 利用不可端末/無効化状態で「現在利用不可」表示が出る
- 権限未許可時に再試行/設定導線が機能する
- reason分類が実機の状態と一致する
 - Health Connectの権限画面にアプリが表示される

## Deployment / Rollout
- 実機検証でHealth Connect利用可否の挙動を確認
- Android 14端末で権限要求フローを確認

## Risks / Open Questions
- healthパッケージがINTERNET権限無しで動作するか実機検証が必要
