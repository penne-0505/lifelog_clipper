---
name: commit
description: Use this when the changes and scope are finalized and it's time to commit.
---

# 目的
- リポジトリの「Git運用規則」に従って、適切なコミットを1つ作成する。
- 規則が複数候補ある場合は、根拠（参照ファイル・直近コミット傾向）を示し、最も妥当な規則に合わせる。

# 事前確認（規則の検出）
1. 規則の一次情報を探索し、要点を箇条書きで整理する（見つからない場合も明記する）。
   - 例: CONTRIBUTING.md / README / docs/* / .github/* / AGENTS.md
   - コミット書式: .gitmessage, commitlint 設定（.commitlintrc* / package.json の commitlint / .config/commitlint*）
   - フック: .husky/*, lefthook.yml, pre-commit 設定, git hooksPath（`git config core.hooksPath`）
2. 直近のコミットメッセージから「慣習」を推定する。
   - `git log -n 30 --pretty=%s` を確認し、支配的なパターンを特定する。
   - 例: Conventional Commits（feat/fix/chore 等）、Jiraキー接頭辞（PROJ-123 など）、角括弧プレフィックス（[PROJ-123]）など。
3. 上記から最優先ルールを確定する。
   - 明確な規則がある場合: それに従う。
   - 規則が曖昧な場合: 直近コミットの最多パターンに従う。
   - それでも不明な場合: Conventional Commits を暫定採用し、採用理由と不確実性を簡潔に記載する。

# 対象ファイル（ステージング）
- 変更を確認し、コミットに含めるべき範囲を最小化してステージする。
1. バイナリや巨大差分、秘密情報（鍵・トークン・個人情報）が含まれていないことを確認する。
2. ステージ後に `git diff --staged` を確認し、意図しない混入がないことを保証する。

# チェック（任意）
- 未指定または false の場合でも、プレコミットフックが存在する場合は、その前提で進める。

# コミットメッセージの生成
以下の入力を優先度順で使用する:
- SUBJECT（最優先。指定があればそれを整形して用いる）
- TYPE / SCOPE（Conventional Commits 系の場合に利用）
- BODY（必要時のみ。行長は原則72文字程度で折り返す）
- ISSUE（参照すべきチケットID等）
- CLOSES=true の場合は「Closes」を使用（プロジェクト規則が許す場合のみ）。false/未指定なら「Refs」等の参照に留める。
- BREAKING=true の場合は破壊的変更の表現（Conventionalなら `!` または BREAKING CHANGE フッタ）を規則に従って付与する。

## 生成ルール（例）
- Conventional Commits が支配的な場合:
  - 件名: `<type>(<scope>)!: <subject>`（scopeや!は必要な場合のみ）
  - フッタ: `Refs: <issue>` または `Closes: <issue>`
- Jiraキー等のプレフィックスが支配的な場合:
  - 件名: `<KEY>: <subject>` または `[<KEY>] <subject>`（直近最多に合わせる）
- いずれの場合も:
  - 具体的かつ短い動詞で開始し、実装詳細より「変更意図」を優先する。
  - 自動生成物のみの変更は、プロジェクト慣習に従い chore 等に寄せる（該当する場合）。

# 実行（git commit）
1. AMEND=true の場合:
   - `git commit --amend` を使用し、メッセージは規則に従って更新する。
2. それ以外:
   - 通常の `git commit` を実行する。
3. NO_VERIFY=true の場合のみ `--no-verify` を付与する（原則として濫用しない）。
4. 実行後、次を出力する:
   - コミットハッシュ（短縮で可）
   - 最終コミットメッセージ（件名＋本文/フッタ）
   - diffstat（`git show --stat --oneline -1` 相当）

# 失敗時の扱い
- フックやチェックが失敗した場合は、失敗理由を短く説明し、必要な修正を行い、再度コミットする。
- 規則検出が不確実な場合でも、勝手に独自流儀は作らない。根拠と暫定方針を必ず明記する。
