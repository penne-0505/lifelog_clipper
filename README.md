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
- It only copies the JSON to the clipboard; it does not upload it.

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
- JSONはクリップボードにコピーするのみで、アップロードは行いません。

### ドキュメント
- 開発向け: `CONTRIBUTING.md`
- プロジェクトドキュメント: `_docs/`
