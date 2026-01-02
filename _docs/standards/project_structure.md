---
title: Project Directory Structure
status: active
draft_status: n/a
created_at: 2026-01-02
updated_at: 2026-01-02
references: []
related_issues: []
related_prs: []
---

## Overview
本プロジェクトのディレクトリ構成は feature-first を採用し、機能ごとに domain/application/presentation/data を分離して責務を明確化する。

## Scope
- `lib/` 配下のアプリケーションコード
- 新機能追加時の配置ルール

## Non-Goals
- Android/iOS/desktopなどプラットフォーム固有の構成ルール
- パッケージ依存構成の最適化

## Structure

### App Entry
- `lib/main.dart`: エントリポイントのみを置く。
- `lib/app/`: アプリ全体のルート構成（`MaterialApp` 等）。

### Features (feature-first)
- `lib/features/<feature>/` を機能単位のルートとする。
- 依存方向は `domain` -> `application` -> `presentation` を基本とし、逆方向の依存は避ける。

#### domain
- エンティティ/値オブジェクト/enum/型
- ドメイン固有のユーティリティ（例: 日付/時刻の整形）
- 外部ライブラリ依存は最小限に留める

#### application
- 状態管理/ユースケース/コントローラ
- 外部I/Oや権限制御などの「操作」をまとめる

#### presentation
- Page/Widget/画面ロジック
- UI以外の集計や永続化ロジックは置かない

#### data (任意)
- リポジトリ実装、データ取得・整形の実装
- 外部パッケージ依存はここに寄せる

## Naming
- ファイル名は `lower_snake_case.dart` を基本とする
- feature 名は英小文字・単数形を基本とする (`health_connect`, `lifelog`)

## Usage
- 既存featureを拡張する場合は、該当feature配下へ追加する
- 既存featureをまたぐ共通処理は、まず feature 内で完結できないか検討する
- 明確に横断的な処理のみ `lib/app/` もしくは共通モジュールの新設を検討する
