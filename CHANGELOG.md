# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed - Documentation Sync (2026-08-16)

- README / CHANGELOG / `.env.example` / 各ガイドを現行実装に合わせて更新
- `TESTING.md` と `docs/README.md`（ドキュメント索引）を追加
- 採用されなかった Playwright ベースのテスト基盤（FEAT-GHA-001）の設計・計画・評価ドキュメントを削除

### Changed - Test Coverage 100% (2026-07-12)

- SimpleCov の閾値を行・ブランチともに **100%** に引き上げ（`spec/rails_helper.rb`）
- 分岐カバレッジ計測（`enable_coverage :branch`）を有効化

### Changed - Ruby 4.0 / Rails 8.1.3 Upgrade (2026-07-12)

#### Runtime & Framework
- **Ruby**: 3.4.6 → 4.0.5 (`.ruby-version`, `Gemfile`, `Dockerfile`, CI)
- **Rails**: 8.1.1 → 8.1.3
- **Gems**: `bundle update` で全gemを最新化（Puma 8.0 / RuboCop 1.88 / slim-rails 4.0 / rspec-rails 8.0.4 / selenium-webdriver 4.46 など）

#### Fixed
- Ruby 4.0 で削除された `CGI.parse` を `Rack::Utils.parse_query` に置換（`spec/requests/manifest_spec.rb`）
- Apple Silicon の Docker で system spec が実行できるよう Debian の `chromium` + `chromium-driver` をイメージに追加し、存在時は Capybara がそれを使用（Chrome for Testing に linux/arm64 版がないため）

#### Verified
- RSpec: 715 examples, 0 failures
- RuboCop: 145 files, no offenses

### Added - Auto Release Workflow (2025-12)

- `main` へのマージ時にパッチバージョンのタグと GitHub Release を自動作成する `.github/workflows/release.yml` を追加

### Added - Progressive Web App (2025-11-29)

#### New Features
- **Service Worker**: `app/javascript/serviceworker.js` を esbuild で `public/serviceworker.js` にバンドル
- **キャッシュ戦略**: `CacheFirstStrategy` / `NetworkFirstStrategy` / `NetworkOnlyStrategy` を `StrategyRouter` がURLパターンで振り分け
- **ライフサイクル管理**: `LifecycleManager` によるプリキャッシュと旧キャッシュの削除
- **動的マニフェスト**: `GET /manifest.json`（`ManifestsController`）をI18n対応で生成
- **PWA設定の外部化**: `config/pwa_config.yml` を環境別に定義し `GET /api/pwa/config` で配信
- **オフラインページ**: `public/offline.html`
- **インストールプロンプト**: `install_prompt_manager.js` による「ホーム画面に追加」制御
- **クライアント計測**: `POST /api/client_logs` / `POST /api/metrics`（`client_logs` / `metrics` テーブルを追加）

#### Testing
- Jest（jsdom）による Service Worker モジュールのユニットテストを追加（閾値80%）
- Capybara + Selenium による PWA システムテスト（`spec/system/pwa_offline_spec.rb`）を追加

### Changed - Rails 8 Authentication Migration (2025-11-26)

#### Breaking Changes (内部実装)
- 認証を Sorcery から Rails 8 標準の `has_secure_password` に移行し、`sorcery` gem を削除
- `operators` テーブルから `crypted_password` / `salt` を削除し `password_digest` を追加

#### New Features
- **プロバイダー抽象**: `Authentication::Provider` / `Authentication::PasswordProvider`
- **サービス層**: `AuthenticationService` / `AuthResult` / `SessionManager`
- **ブルートフォース対策**: `BruteForceProtection` concern によるアカウントロック
- **レート制限**: `rack-attack` によるログイン・パスワードリセットのスロットリング
- **ヘルスチェック**: `GET /health/ready` を追加
- **認証メトリクス**: `auth_attempts_total` / `auth_duration_seconds` / `auth_failures_total` / `auth_locked_accounts_total` / `auth_active_sessions`
- **リクエスト相関**: `RequestCorrelation` ミドルウェアによる `X-Request-ID` の伝播
- **移行検証**: `DataMigrationValidator` / `PasswordMigrator`

#### Configuration
- `config/initializers/authentication.rb` を追加（`AUTH_*` 環境変数で設定を上書き可能）
- `config/initializers/rack_attack.rb` を追加

### Changed - MySQL 8 Unification (2025-11)

- 開発・テスト・本番の全環境を MySQL 8.0 に統一（`config/database.yml` / `docker-compose.yml`）

### Added - LINE Bot SDK Modernization (2025-11-17)

#### New Features
- **Health Check Endpoints**:
  - `GET /health` - Shallow health check for load balancers
  - `GET /health/deep` - Deep health check verifying database and LINE credentials
- **Prometheus Metrics**: `GET /metrics` endpoint for monitoring
  - Webhook processing duration and success rate
  - LINE API call metrics
  - Group count gauge
  - Message send counters
- **Structured Logging**: JSON-formatted logs with correlation IDs via Lograge
- **Error Sanitization**: Automatic removal of sensitive data from error messages

#### Architecture Improvements
- **Service-Oriented Architecture**: Replaced monolithic `CatLineBot` with focused services:
  - `Line::EventProcessor` - Core webhook orchestration
  - `Line::GroupService` - Group lifecycle management
  - `Line::CommandHandler` - Special command processing
  - `Line::OneOnOneHandler` - 1-on-1 chat handling
- **Client Abstraction**: `Line::ClientAdapter` interface for SDK isolation
- **Reusable Utilities**:
  - `Webhooks::SignatureValidator` - Webhook signature verification
  - `Resilience::RetryHandler` - Exponential backoff retry logic
  - `ErrorHandling::MessageSanitizer` - Credential leak prevention
  - `Line::MemberCounter` - Member counting with graceful degradation
  - `PrometheusMetrics` - Centralized metrics tracking

#### Reliability Enhancements
- **8-second Timeout Protection**: Prevents webhook processing from exceeding LINE's limits
- **Transaction Management**: Atomic operations for data consistency
- **Idempotency Tracking**: Prevents duplicate processing of webhooks
- **Retry Logic**: Exponential backoff for transient failures (max 3 attempts)
- **Graceful Degradation**: Member count fallback (default: 2)

#### Security Improvements
- **Timing Attack Prevention**: Secure signature comparison via `ActiveSupport::SecurityUtils`
- **Credential Protection**: MessageSanitizer removes sensitive data from logs
- **Error Message Safety**: Sanitized error notifications prevent information leakage

#### Developer Experience
- **Dependency Injection**: All services accept dependencies for easy testing
- **Comprehensive Documentation**: YARD docs for all classes and methods
- **Test Helpers**: Reusable test utilities in `spec/support/`
- **100% Backward Compatible**: No breaking changes to existing functionality

### Changed

#### Updated Dependencies
- `line-bot-api`: Updated to `~> 2.0` (from implicit v1.x)
- Added `prometheus-client ~> 4.0` for metrics collection
- Added `lograge ~> 0.14` for structured logging
- Added `request_store ~> 1.5` for request-scoped storage

#### Modified Files
- `app/controllers/operator/webhooks_controller.rb`:
  - Now uses `Line::EventProcessor` instead of `CatLineBot`
  - Integrated `Webhooks::SignatureValidator`
  - Added timeout protection and error handling
  - Returns appropriate HTTP status codes (200, 400, 503)
- `app/models/scheduler.rb`:
  - Migrated to `Line::ClientProvider`
  - Added `Resilience::RetryHandler` for reliability
  - Improved transaction safety
  - Enhanced error logging with sanitization
- `config/routes.rb`:
  - Added `/health` and `/health/deep` routes
  - Added `/metrics` route

#### New Configuration Files
- `config/initializers/lograge.rb` - Structured logging configuration
- `config/initializers/prometheus.rb` - Metrics definitions (7 metrics)
- `config/environments/production.rb` - Log rotation (10 files, 100MB)

### Removed

- `app/models/cat_line_bot.rb` (89 lines) - Replaced by service architecture
- `app/models/concerns/message_event.rb` (60 lines) - Logic moved to handlers

### Technical Details

#### Code Quality
- **RuboCop Clean**: 0 blocking violations
- **Test Coverage**: 88.06% (target: ≥90%)
- **Created Files**: 18 new files
- **Deleted Files**: 2 legacy files
- **Net Code Change**: +600 lines (149 deleted, 600+ added)

#### Performance Impact
- **Webhook Processing**: No regression, improved error handling
- **Memory Usage**: Slightly increased due to new services (acceptable)
- **Cold Start**: +50ms for additional service initialization

### Migration Notes

- **Zero Downtime**: Deployment can be done without service interruption
- **No Database Changes**: Existing schema remains unchanged
- **Credential Migration**: Not required - same structure
- **Rollback**: Simple git revert, no data migration needed

See [MIGRATION_GUIDE.md](docs/MIGRATION_GUIDE.md) for detailed migration instructions.

---

## Previous Releases

2025-11-17 より前の変更履歴は記録されていません。詳細は
[コミット履歴](https://github.com/Tsuchiya2/ReLINE/commits/main) と
[リリース一覧](https://github.com/Tsuchiya2/ReLINE/releases) を参照してください。
