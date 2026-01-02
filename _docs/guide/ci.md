---
title: CI Build and Release
status: active
draft_status: n/a
created_at: 2026-01-02
updated_at: 2026-01-02
references:
  - _docs/standards/git_workflow.md
  - .github/workflows/build-and-release.yml
related_issues: []
related_prs: []
---

## Overview
`main` へのコミット時に、GitHub Actions でFlutterのビルドとリリースを行います。

## Workflow
- Trigger: `main` への push
- Steps: `flutter pub get` → `flutter analyze --no-fatal-warnings --no-fatal-infos` → `flutter test` → `flutter build apk --release`
- Release: ビルド済みAPKをGitHub Releaseに添付

## Release Naming
- Tag: `build-YYYYMMDD-<run_number>`
- Name: `Build build-YYYYMMDD-<run_number>`

## Artifacts
- APK: `build/app/outputs/flutter-apk/app-release.apk`

## Notes
- 署名設定は未導入のため、必要に応じてワークフローに署名手順を追加する。
