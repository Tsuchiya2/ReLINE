# ドキュメント一覧

`docs/`配下のドキュメントの案内です。**運用ドキュメント**は常に実装と同期させる対象、**開発履歴**は当時の意思決定を残すための記録であり、現在の実装と一致しない記述が含まれる場合があります。

---

## 運用ドキュメント（実装と同期）

| ドキュメント | 内容 |
|--------------|------|
| [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) | LINE Bot SDK v2 / サービス指向アーキテクチャへの移行手順、ヘルスチェック・メトリクスの使い方 |
| [observability/authentication-monitoring.md](observability/authentication-monitoring.md) | 認証まわりの構造化ログ・Prometheusメトリクス・アラート設計 |
| [deployment/ROLLBACK.md](deployment/ROLLBACK.md) | Rails 8認証移行のロールバック手順 |
| [usage-examples/data_migration_validator_usage.md](usage-examples/data_migration_validator_usage.md) | `DataMigrationValidator`の使い方 |
| [lighthouse-pwa-audit.md](lighthouse-pwa-audit.md) | PWAのLighthouse監査観点と対応状況 |

リポジトリ直下にも以下のドキュメントがあります。

- [../README.md](../README.md) - プロジェクト概要・セットアップ
- [../TESTING.md](../TESTING.md) - テストの実行方法とカバレッジ方針
- [../CHANGELOG.md](../CHANGELOG.md) - 変更履歴
- [../spec/system/PWA_TESTING_README.md](../spec/system/PWA_TESTING_README.md) - PWAシステムテストのガイド
- [../spec/javascript/README.md](../spec/javascript/README.md) - Service WorkerのJestテストガイド

---

## 開発履歴（当時の記録）

各機能の設計・計画・評価・実装レポートです。**作成時点のスナップショット**であり、更新は行いません。現在の仕様はソースコードと上記の運用ドキュメントを参照してください。

| ディレクトリ | 内容 |
|--------------|------|
| `designs/` | 設計ドキュメント |
| `plans/` | タスク計画 |
| `evaluations/` | 設計・計画・実装に対する各種評価 |
| `reviews/` | 実装レビュー |
| `implementation-reports/` | フェーズごとの実装レポート |

### 機能別インデックス

| 機能ID | 機能 | 主なドキュメント |
|--------|------|------------------|
| FEAT-LINE-SDK-001 | LINE Bot SDK v2へのモダナイゼーション | [designs/line-sdk-modernization.md](designs/line-sdk-modernization.md) / [plans/line-sdk-modernization-tasks.md](plans/line-sdk-modernization-tasks.md) / [implementation-reports/phase-6-controller-scheduler-updates.md](implementation-reports/phase-6-controller-scheduler-updates.md) |
| FEAT-AUTH-001 | SorceryからRails 8 `has_secure_password`への移行 | [designs/rails8-authentication-migration.md](designs/rails8-authentication-migration.md)（iteration 2） / [designs/rails8-authentication-migration-v1.md](designs/rails8-authentication-migration-v1.md)（iteration 1） / [plans/rails8-authentication-migration-tasks.md](plans/rails8-authentication-migration-tasks.md) |
| FEAT-DB-001 | 全環境のMySQL 8統一 | [designs/mysql8-unification.md](designs/mysql8-unification.md) / [plans/mysql8-unification-tasks.md](plans/mysql8-unification-tasks.md) |
| PWA | Progressive Web App対応 | [designs/pwa-implementation.md](designs/pwa-implementation.md) / [plans/pwa-implementation-tasks.md](plans/pwa-implementation-tasks.md) / [reviews/pwa-implementation-alignment-evaluation.md](reviews/pwa-implementation-alignment-evaluation.md) |

> Playwrightベースのシステムテスト基盤（FEAT-GHA-001）は設計・計画のみで採用されず、実装はSelenium WebDriverのままです。誤解を避けるため関連ドキュメントは削除しました。
