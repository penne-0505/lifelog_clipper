---
title: "LifeLog Clipper Requirements (MVP)"
status: active
draft_status: exploring
created_at: 2026-01-02
updated_at: 2026-01-02
references:
  - _docs/archives/plan/Core/lifelog-clipper-mvp/plan.md
  - _docs/intent/Core/health-connect-test-deferral.md
  - _docs/intent/Core/lifelog-clipper-mvp.md
related_issues: []
related_prs: []
---

# "LifeLog Clipper" 要件定義書（MVP）

## 1. 背景と目的

### 1.1 背景

* ChatGPTに貼り付けるための「ライフログ（歩数・睡眠・心拍）」を、端末内のHealth Connectから取得し、日別JSONとしてクリップボードへコピーできる形にする。

### 1.2 目的

* 直近7日分について、任意の日付のログを **純JSON** として即時コピーできること。
* 個人利用を前提に、堅牢性・多機能性よりも「取得できる」「貼れる」「解釈できる」を優先する。

### 1.3 非目的（スコープ外）

* サーバー提供（HTTP API）や外部連携（クラウド同期、複数端末共有）
* 長期履歴（30日超）を恒常的に扱う仕組み
* 解析・可視化（チャート、統計ダッシュボード）

---

## 2. 実装方針（技術選定）

### 2.1 実装言語・フレームワーク

* Flutter（Dart）で実装する。

### 2.2 Health Connect連携方式

* 第一候補：Flutterラッパーを採用する（候補：`health` パッケージ）。([Dart packages][1])
* 代替案：必須項目（歩数・心拍・睡眠ステージ/セッション）が取得できない、または取得品質に制約がある場合に限り、Kotlin（Platform Channel）で該当部分を自前実装に切替する。

#### 2.2.1 取得可否の事前確認（必須項目）

`health` パッケージは、Health Connect対応を明示し、少なくとも以下のデータ型をサポート対象として列挙しています。([Dart packages][1])

* 歩数：`STEPS`（Google Health Connect: yes）([Dart packages][1])
* 心拍：`HEART_RATE`（Google Health Connect: yes）([Dart packages][1])
* 睡眠（セッション/ステージ相当）：

  * `SLEEP_SESSION`（Google Health Connect: yes）([Dart packages][1])
  * `SLEEP_LIGHT / SLEEP_DEEP / SLEEP_REM / SLEEP_AWAKE`（Google Health Connect: yes）([Dart packages][1])
  * `SLEEP_ASLEEP` は Android 側で `STAGE_TYPE_SLEEPING` に対応する旨の注記あり ([Dart packages][1])
  * `SLEEP_IN_BED` / `SLEEP_AWAKE_IN_BED` は Health Connect で未対応のため取得対象外とする（取得時に例外が発生する）。

よって、MVPの必須指標は **Flutterラッパー（`health`）で満たせる可能性が高い**、という前提で進めます。([Dart packages][1])

---

## 3. 動作環境・前提

### 3.1 対象端末

* Android端末のみ（iOSは対象外）
* 最低対応OS：Android 9
* 推奨OS：Android 14

### 3.2 Health Connectの前提

* Android 14 では Health Connect が端末設定からアクセス可能（統合）である。([Google ヘルプ][2])
* 端末やOSバージョンによっては、Health Connectが利用不可になりうる（未インストール、無効、非対応等）。

### 3.3 権限（想定）

* Health ConnectのREAD権限（歩数・心拍・睡眠関連）
* 歩数取得のために `ACTIVITY_RECOGNITION` が必要になる場合がある（`health`のセットアップ説明に記載）。([Dart packages][1])
* 直近7日運用のため、原則として「30日超の履歴権限（READ_HEALTH_DATA_HISTORY）」は不要。なお `health` は「デフォルトで30日制限がある」旨を記載している。([Dart packages][1])
* 運用方針として、歩数・心拍・睡眠の**全権限が揃うまでは利用可能扱いにしない**（いずれか不足時は「権限が必要」表示に戻す）。

### 3.4 ネットワーク

* 端末内完結を前提とし、**INTERNET権限は付与しない**。
* 留意：`health` のREADMEには「端末がインターネットへアクセスできる必要がある」との記述があるため、INTERNET権限無し運用の可否は実機で検証する（要リスク管理）。([Dart packages][1])

---

## 4. 機能要件

### 4.1 画面要件（単一画面）

* 起動時に自動で読み込みを開始する。
* 直近7日を日付リストとして表示する（推奨：今日→過去の降順）。
* 各行に「コピー」ボタンを配置し、押下時に当日分のJSONを **都度生成** してクリップボードに格納する。
* 読み込み中は、ボタンの無効化・スピナー表示等のマイクロインタラクションを実装する（状態が視覚的に判別できること）。

### 4.2 Health Connect利用不可時の挙動

* 起動時にHealth Connectの利用可否を判定する。
* 利用不可の場合は **権限要求を行わず**、UIに **「現在利用不可」** を明示表示する。
* コピーは可能とし、生成する日別JSONの「健康データ値」は **全てnull** とする（後述のスキーマで定義）。

### 4.3 権限要求フロー（起動時）

* Health Connectが利用可能な場合、アプリ起動時に即座に権限要求を行う。
* 権限が未許可または拒否された場合、UIに **「権限が必要」** を表示し、以下の両導線を用意する。

  * 再試行ボタン（同一権限の再要求）
  * 設定を開くボタン（OS設定/Health Connect設定への遷移）

### 4.4 取得対象データ

* 歩数：日別合計
* 心拍：日別の min / max / 時間重み付き平均 / サンプル数
* 睡眠：日別windowに重なるセッション全件＋ステージ（詳細）

  * さらにサマリ（セッション基準の合計分、ステージ別分数、セッション数）を付与

### 4.5 取得API方針（暫定）

* 取得は「直近7日windowを一括取得 → 日別windowに分割」を基本とし、API呼び出し回数を抑える。
* 歩数は集計APIが利用できる場合は日別windowで取得する。集計APIがない場合は `STEPS` レコード取得後に日別合算する。
* 心拍は `HEART_RATE` の時刻付きサンプル列を取得し、日別windowにクリップして `min/max/samples_count` と時間重み付き平均を算出する。
* 睡眠は `SLEEP_SESSION` とステージ系を取得し、日別windowにクリップして `sleep_sessions` を構成する。
* `sleep_summary.by_stage_minutes` はステージ区間を日別windowにクリップし、重複除外のルールに従って算出する。
* ステージ情報が取得不能な場合は `sleep_sessions` のみ出力し、`sleep_summary` は null 方針に従う。

---

## 5. 非機能要件

### 5.1 ログ方針（プライバシー）

* 生成されたJSON本文（個人健康データ）はログに出力しない。
* ログは原則として「実行した処理（例：権限要求、取得件数、集計完了）」のみ。
* デバッグでどうしても必要な場合は一時的に記述してよいが、**mainブランチには含めない**（運用ルール）。

### 5.2 データ保存

* 永続化は原則しない（コピー用途に限定）。必要が生じた場合も「ローカル端末内のみ」で検討する。

### 5.3 互換性（スキーマ）

* `schema_version` を導入し、破壊的変更時にインクリメントする。
* JSONのフィールド順序は **完全固定** とする（差分確認・安定貼付を容易にする）。

#### 5.3.1 フィールド順固定の実装方針

* JSON生成は専用の出力DTO（クラス）に集約する。
* `toJson()` は **キーを固定順で挿入した Map** を返す（DartのMap挿入順を前提）。
* JSON生成は必ず同一経路（DTO）を経由し、順序が崩れる経路を作らない。

---

## 6. データ仕様（JSON）

### 6.1 基本方針

* 形式：JSONのみ
* pretty print：2スペースインデント
* 日別：1日=1JSON（直近7日分はUIで選択してコピー）

### 6.2 日別window定義

* `timezone`：`Asia/Tokyo` 固定
* `window`：半開区間 `[start, end)`

  * 通常日：`00:00:00`〜翌日`00:00:00`
  * 今日：`00:00:00`〜`generated_at`

#### 6.2.1 timezone 固定の理由

* 個人利用のみのため、常用する `Asia/Tokyo` に固定して運用する。

### 6.3 日別JSONスキーマ（フィールド順固定）

```json
{
  "schema_version": 1,
  "generated_at": "YYYY-MM-DDTHH:MM:SS+09:00",
  "date": "YYYY-MM-DD",
  "timezone": "Asia/Tokyo",
  "window": {
    "start": "YYYY-MM-DDT00:00:00+09:00",
    "end": "YYYY-MM-DDT00:00:00+09:00"
  },
  "availability": {
    "health_connect": "available|unavailable",
    "reason": "string|null"
  },
  "steps": {
    "total": 12345
  },
  "heart_rate": {
    "min_bpm": 55,
    "avg_bpm_time_weighted": 72.4,
    "max_bpm": 118,
    "samples_count": 360
  },
  "sleep_summary": {
    "total_minutes_session_basis": 420,
    "sessions_count": 2,
    "by_stage_minutes": {
      "UNKNOWN": 0,
      "AWAKE": 15,
      "SLEEPING": 0,
      "OUT_OF_BED": 0,
      "LIGHT": 210,
      "DEEP": 120,
      "REM": 75
    }
  },
  "sleep_sessions": [
    {
      "start": "YYYY-MM-DDTHH:MM:SS+09:00",
      "end": "YYYY-MM-DDTHH:MM:SS+09:00",
      "stages": [
        { "start": "…", "end": "…", "stage": "LIGHT|DEEP|REM|AWAKE|OUT_OF_BED|SLEEPING|UNKNOWN" }
      ]
    }
  ]
}
```

### 6.4 利用不可時のnull方針

`availability.health_connect="unavailable"` の場合、以下を適用する。

* `availability.reason` は以下の固定値から選択する。

  * `not_installed`（Health Connectアプリ/統合機能が無い）
  * `disabled`（無効化/利用不可）
  * `unsupported`（端末/OS非対応）
  * `unknown`（判定不能）
* `steps.total=null`
* `heart_rate.*=null`（`samples_count` も null）
* `sleep_summary.*=null`（`by_stage_minutes` も全stageをnull）
* `sleep_sessions=null`
* `window/date/generated_at/timezone/schema_version/availability` は出力する（貼り付け後の解釈とデバッグのため）

### 6.5 丸め・欠損・生成時刻のルール

* `generated_at` は **コピー押下時**の時刻を使用する（ミリ秒は切り捨て、秒まで出力）。
* `steps.total` は整数。
* `heart_rate.min_bpm` / `max_bpm` は整数。
* `heart_rate.avg_bpm_time_weighted` は小数第1位で四捨五入。
* `sleep_summary.*_minutes` は整数分（秒以下は切り捨て）。
* 心拍サンプルが0件の場合は `heart_rate.*` を **全てnull** とする。
* `sleep_sessions` が0件の場合は空配列 `[]` とする（取得不能時のみ `null`）。
* 取得失敗（APIエラー等）の場合は、対象日の健康データ値を null 方針で出力する。

---

## 7. 集計仕様

### 7.1 歩数（steps.total）

* 当日window内の歩数レコードを合算する（実装はプラグインの提供APIに準拠）。

### 7.2 心拍（時間重み付き平均）

* 対象：当日window内の心拍サンプル列（時刻付き）
* 定義：サンプル列を時刻昇順に並べ、区間長を重みとして平均する。

  * 例：`(bpm_i * Δt_i)` の総和 ÷ `Δt` 総和
  * 最後のサンプルは `window.end` までを `Δt_last` とする（`window.end` が `generated_at` の日はその時刻まで）
* `min_bpm/max_bpm` はサンプルの最小/最大、`samples_count` はサンプル数。

※Health Connectの心拍がサンプル列（series）を持つことは、公式ドキュメントで説明されている。([Android Developers][3])

### 7.3 睡眠（重複除外）

* `sleep_sessions` は **終了日が当日**のセッションを対象とする。
* 各セッションの `start/end` は **元のセッション時刻** を出力する（00:00でのクリップは行わない）。
* `sleep_summary.total_minutes_session_basis` はセッション区間の合計分（ステージ基準ではない）。
* `sleep_summary.by_stage_minutes` はセッション内のステージ区間を集計し、**重複区間は除外**して算出する。
* `sleep_sessions` は `start` 昇順で出力する。
* 各セッション内の `stages` も `start` 昇順で出力する。
* ステージ情報がないセッションは `stages: []` とする。
* セッションが0件の場合は `sleep_sessions: []` とする（取得不能時のみ `null`）。

#### 7.3.0 睡眠日の扱い（起床日ベース）

* 睡眠は **セッション終了日（起床日）で日付を決定する**。
* `sleep_sessions` と `sleep_summary` は、終了日が当日のセッションに含まれる。
* 日付境界（00:00）でのクリップは行わず、夜〜朝の連続セッションを同日にまとめる。

#### 7.3.1 ステージ分類のマッピング方針

* Health Connectのステージは最大限保持し、未対応は `UNKNOWN` に寄せる。
* `Awake` → `AWAKE`
* `Light` → `LIGHT`
* `Deep` → `DEEP`
* `REM` → `REM`
* `Out of bed` → `OUT_OF_BED`
* `Sleeping`（ステージ不明の睡眠）→ `SLEEPING`
* 不明/未対応/欠損 → `UNKNOWN`
* `SLEEP_ASLEEP` が取得できる場合は `SLEEPING` に統一する。

重複除外の大枠ルール（簡略・MVP）：

* ステージ区間を時刻順に処理し、既にカウント済みの時間帯は除外する（集合の和集合長として加算）。
* 重複が発生した場合は「後から現れた区間を優先」する（実装容易性を優先）。
  ※将来必要になれば、優先順位（AWAKE優先等）へ拡張可能。

---

## 8. UI仕様（マイクロインタラクション）

* 起動時：自動読み込み開始、各行はローディング表示（スケルトン/スピナー等）。
* コピー押下時：

  * ボタンを一時的に「処理中」状態（無効化＋インジケータ）
  * 成功時にトースト等で「コピー完了」を通知
  * 失敗時に理由を短く通知（権限不足、利用不可等）

---

## 9. 実装上の注意点（Flutter/Android）

* `health` のAndroid 14注意として、権限要求処理の都合で `MainActivity` を `FlutterFragmentActivity` にする必要がある旨が記載されている。([Dart packages][1])
* Manifestに Health Connect の `queries` を記載し、データ型に対応するREAD権限を宣言する（`health`/`flutter_health_connect` いずれも同趣旨の記載）。([Dart packages][1])
* Health Connectの権限導線のため、`ACTION_SHOW_PERMISSIONS_RATIONALE` を `queries` と `intent-filter` に追加し、`activity-alias` を定義する。

---

## 10. 検証項目（最低限）

* Health Connect利用可/不可の判定がUIに反映されること（「現在利用不可」）。
* 直近7日の各日で、JSONのフィールド順が常に同一であること。
* 心拍の時間重み付き平均が、サンプル間隔の不均一でも破綻しないこと。
* 睡眠ステージの重複がある場合に、`by_stage_minutes` が二重計上されないこと。
* INTERNET権限無しで `health` が動作するか（README記述との整合確認）。([Dart packages][1])
* 欠損ステージ端末での検証は当面見送りとする（`_docs/intent/Core/health-connect-test-deferral.md` を参照）。
