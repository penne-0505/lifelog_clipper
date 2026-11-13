# lifelog_clipper

日英あり / English + Japanese

## English

### Overview
LifeLog Clipper is a Flutter app that creates JSON logs of body information for
LLMs or lifelog apps.

### Features
- Connects to Health Connect (Android).
- Builds recent daily logs (default: last 7 days).
- Copies JSON to the clipboard.
- Optional HTTP auto-export: POSTs the aggregated JSON to a user-configured
  endpoint (header `x-ingest-secret`), manually via "Send now" or periodically
  every 15 minutes via WorkManager (covers the last 48 hours). Disabled until
  an endpoint URL is set in the app.

### Requirements
- Flutter 3.18.0 (stable) or newer.
- Dart 3.1+ (included with Flutter).
- Android SDK 33 (Platform 33 + Build Tools 33.0.0+).
- Android Studio / VS Code / IntelliJ (any Flutter-capable IDE).
- (The target device must run Android 9.0 or newer; Android 14+ is recommended.)

### Setup
```bash
flutter --version
flutter doctor
flutter doctor --android-licenses
flutter pub get
flutter analyze
flutter test
```

### Run (Android)
```bash
flutter run
```

### Build (Android)
```bash
flutter build apk
```

### Notes on Data & Privacy
- The app reads data from Health Connect and generates JSON on demand.
- By default it only copies the JSON to the clipboard. Uploading happens only
  when the user explicitly configures the HTTP auto-export endpoint.

### Documents
- Development details: `CONTRIBUTING.md`
- Project documentation: `_docs/`

---

## 日本語

### 概要
LifeLog Clipper は、LLM やライフログアプリに渡すための身体情報ログJSONを作成する
Flutter アプリです。

### 主な機能
- Health Connect（Android）に接続。
- 直近の日別ログ（既定: 7日分）を生成。
- JSON をクリップボードへコピー。
- 任意の HTTP 自動送信：設定した送信先へ集計 JSON を POST（ヘッダ `x-ingest-secret`）。
  「今すぐ送信」の手動送信と、WorkManager による15分間隔の定期送信（直近48時間分を対象）に対応。
  送信先URLを設定するまで無効。

### 前提条件
- Flutter 3.18.0（stable）以上。
- Dart 3.1 以上（Flutter に同梱）。
- Android SDK 33（Platform 33 + Build Tools 33.0.0 以上）。
- Android Studio / VS Code / IntelliJ（Flutterが扱えるIDE）。
- (インストール先の端末は Android 9.0 以上が必須、推奨は Android 14以上です。)

### セットアップ
```bash
flutter --version
flutter doctor
flutter doctor --android-licenses
flutter pub get
flutter analyze
flutter test
```

### 実行（Android）
```bash
flutter run
```

### ビルド（Android）
```bash
flutter build apk
```

### データ/プライバシーに関する注意
- Health Connect からデータを取得し、必要に応じてJSONを生成します。
- 既定ではJSONはクリップボードにコピーするのみです。HTTP自動送信の送信先を
  ユーザーが明示的に設定した場合に限り、アップロードを行います。

### ドキュメント
- 開発向け: `CONTRIBUTING.md`
- プロジェクトドキュメント: `_docs/`
