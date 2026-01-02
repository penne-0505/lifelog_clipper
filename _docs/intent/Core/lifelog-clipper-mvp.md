---
title: "LifeLog Clipper MVP Intent"
status: active
draft_status: n/a
created_at: 2026-01-02
updated_at: 2026-01-02
references:
  - _docs/draft/requirements.md
  - _docs/archives/plan/Core/lifelog-clipper-mvp/plan.md
  - _docs/archives/plan/Core/lifelog-clipper-mvp/health-connect-integration.md
  - _docs/archives/plan/Core/lifelog-clipper-mvp/data-aggregation-json.md
  - _docs/archives/plan/Core/lifelog-clipper-mvp/ui-clipboard-flow.md
  - _docs/intent/Core/health-connect-test-deferral.md
related_issues: []
related_prs: []
---

## Overview
LifeLog Clipper MVPの設計判断と実装上の方針をまとめ、完了済みとして記録する。

## Background
- Health Connectから取得した歩数/心拍/睡眠を日別JSONとしてコピーする最小構成を優先した。
- 端末内完結と固定スキーマを重視し、外部連携や長期保存は除外した。

## Decisions
- Health Connectの可否判定と権限導線を起点に、利用不可でもJSON出力を維持する。
- 直近7日windowを一括取得し、日別に分割・集計する。
- JSONフィールド順を固定し、貼り付け先での差分確認を容易にする。

## Validation
- 端末実機でHealth Connectの可否判定/権限導線/データ取得/コピー導線を確認済み。
- INTERNET権限なしでの動作検証を完了済み。
- 欠損ステージ端末の検証も完了済み。

## Consequences
- MVP計画ドキュメントをアーカイブへ移送し、intentを正の参照点とする。
