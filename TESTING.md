# テストガイド

ReLINEのテストは、Ruby側の **RSpec** と、Service Workerモジュール向けの **Jest** の2系統で構成されています。

| 対象 | フレームワーク | 設定ファイル | 実行コマンド |
|------|----------------|--------------|--------------|
| Rails（モデル / サービス / リクエスト / システム） | RSpec | `.rspec` / `spec/rails_helper.rb` | `bundle exec rspec` |
| Service Workerモジュール（キャッシュ戦略 / `strategy_router` / `lifecycle_manager` / `config_loader`） | Jest | `jest.config.js` / `babel.config.json` | `npm test` |

`app/javascript/pwa/`配下でも`install_prompt_manager.js`と`service_worker_registration.js`は
`app/javascript/application.js`から読み込まれるブラウザ側モジュールで、Jestの対象外です
（`jest.config.js`の`collectCoverageFrom`を参照）。

以降のコマンドはDocker環境での実行を前提としています。ローカルに直接Ruby/Nodeを用意している場合は`docker compose exec web`を除いて実行してください。

---

## 1. RSpec

### 実行

```bash
# 全テスト
docker compose exec web bundle exec rspec

# ディレクトリ単位
docker compose exec web bundle exec rspec spec/services
docker compose exec web bundle exec rspec spec/requests
docker compose exec web bundle exec rspec spec/system

# ファイル・行単位
docker compose exec web bundle exec rspec spec/models/line_group_spec.rb
docker compose exec web bundle exec rspec spec/models/line_group_spec.rb:42

# 失敗したテストのみ再実行
docker compose exec web bundle exec rspec --only-failures
```

`.rspec`で`--format documentation`が指定されているため、既定で各exampleの説明が出力されます。

### ディレクトリ構成

```text
spec/
├── channels/     # ActionCable
├── controllers/  # コントローラスペック
├── factories/    # FactoryBot定義
├── helpers/      # ヘルパー
├── javascript/   # Jest（RSpecの対象外）
├── jobs/         # ActiveJob
├── mailers/      # ActionMailer
├── middleware/   # Rackミドルウェア
├── models/       # モデル・concern
├── requests/     # リクエストスペック（API / manifest / metrics）
├── services/     # サービスオブジェクト
├── support/      # 共通ヘルパー・Capybara設定
├── system/       # Selenium + CapybaraによるE2E
└── validators/   # カスタムバリデータ
```

`spec/support/**/*.rb`は`spec/rails_helper.rb`から自動で読み込まれます。

| ヘルパー | 内容 |
|----------|------|
| `spec/support/capybara.rb` | ヘッドレスChromeドライバの登録（`:headless_chrome` / `:headless_chrome_pwa`） |
| `spec/support/authentication_helpers.rb` | 認証まわりの共通処理 |
| `spec/support/login_macros.rb` | ログイン操作のマクロ |
| `spec/support/line_test_helpers.rb` | LINE Webhookのテストデータ生成 |
| `spec/support/pwa_helpers.rb` | Service Worker / Cache APIの検証ヘルパー |

---

## 2. カバレッジ（SimpleCov）

SimpleCovは`CI=true`または`COVERAGE=true`のときだけ有効になります。

```bash
docker compose exec web bash -c "COVERAGE=true bundle exec rspec"
```

`spec/rails_helper.rb`の設定は以下のとおりです。

- **最低カバレッジ**: 行 **100%** / ブランチ **100%**（`enable_coverage :branch`）
- **計測対象**: `{app,lib}/**/*.rb`（`track_files`により未ロードのファイルも計測）
- **除外**: `/spec/`、`/config/`、`/vendor/`、`/test/`
- **出力**: HTML（`coverage/index.html`）とコンソールサマリ

閾値を下回るとRSpecプロセスが失敗終了します。カバレッジ不足の箇所は`coverage/index.html`で確認できます。

---

## 3. システムテスト（Selenium）

システムスペックはCapybara + Selenium WebDriver + ヘッドレスChromeで実行します。

- ドライバは`spec/support/capybara.rb`で登録され、`type: :system`のテストには既定で`:headless_chrome`が適用されます。
- `/usr/bin/chromium`と`/usr/bin/chromedriver`が存在する場合はそれを優先して使用します。Chrome for Testingにlinux/arm64ビルドが無いため、Apple SiliconのDocker環境ではDebianのChromium/chromedriverが必要です（Dockerイメージに同梱済み）。
- 存在しない環境（GitHub Actionsなど）ではSelenium Managerが自動的にChrome/chromedriverを解決します。
- 失敗時のスクリーンショットは`tmp/capybara/`に保存されます。

```bash
docker compose exec web bundle exec rspec spec/system
```

PWAのオフライン動作テストについては[spec/system/PWA_TESTING_README.md](spec/system/PWA_TESTING_README.md)を参照してください。

---

## 4. JavaScriptテスト（Jest）

Service Workerのキャッシュ戦略・ライフサイクル・設定ローダーはJestでテストします。

```bash
# 全テスト
docker compose exec web npm test

# ウォッチモード
docker compose exec web npm run test:watch

# カバレッジ付き
docker compose exec web npm run test:coverage
```

- テスト対象ファイル: `spec/javascript/**/*.test.js`
- 環境: `jsdom`（`spec/javascript/setup.js`でCache API / fetch / Service Workerグローバルをモック）
- カバレッジ閾値: branches / functions / lines / statements すべて **80%**

詳細は[spec/javascript/README.md](spec/javascript/README.md)を参照してください。

---

## 5. 静的解析・セキュリティ

```bash
# RuboCop（Rails / Performance / RSpec 拡張つき）
docker compose exec web bundle exec rubocop

# 自動修正
docker compose exec web bundle exec rubocop -a

# 静的セキュリティ解析
docker compose exec web bundle exec brakeman

# 依存gemの脆弱性チェック
docker compose exec web bundle exec bundler-audit check --update
```

---

## 6. CI

GitHub Actionsで以下のワークフローが動作します。

| ワークフロー | ファイル | トリガー | 内容 |
|--------------|----------|----------|------|
| RSpec Tests | `.github/workflows/rspec.yml` | `main` / `develop`へのpush・PR | MySQL 8.0サービスを起動し、アセットをビルドしてRSpecを実行。カバレッジとテスト結果をアーティファクトとして保存 |
| Rubocop | `.github/workflows/rubocop.yml` | `main` / `master`へのpush、全PR | RuboCopによる静的解析 |
| Auto Release | `.github/workflows/release.yml` | `main`へのpush | パッチバージョンを進めてGitHub Releaseを自動作成 |

CIでは`CI=true`と`COVERAGE=true`が設定されるため、SimpleCovの100%閾値がそのまま適用されます。

---

## 7. トラブルシューティング

### システムテストがChromeの起動に失敗する

Docker環境ではイメージにChromium/chromedriverが同梱されています。イメージが古い場合は再ビルドしてください。

```bash
docker compose build web
```

### カバレッジが100%に届かない

```bash
docker compose exec web bash -c "COVERAGE=true bundle exec rspec"
```

を実行し、`coverage/index.html`で未カバー行を確認します。分岐カバレッジも必須のため、`if`/`rescue`/`&.`などの片側だけを通るケースにも注意してください。

### `ActiveRecord::PendingMigrationError`が出る

テスト用スキーマが古い状態です。

```bash
docker compose exec web bin/rails db:test:prepare
```

### Jestが`Cannot find module`で失敗する

依存関係が未インストールです。

```bash
docker compose exec web npm ci
```
