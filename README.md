<div align="center">

# 🐱 ReLINE - 猫メッセンジャーBot

[![Ruby](https://img.shields.io/badge/Ruby-4.0.5-CC342D?style=flat&logo=ruby&logoColor=white)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.1.3-CC0000?style=flat&logo=ruby-on-rails&logoColor=white)](https://rubyonrails.org/)
[![LINE](https://img.shields.io/badge/LINE-Messaging_API-00C300?style=flat&logo=line&logoColor=white)](https://developers.line.biz/en/services/messaging-api/)

**かわいい猫の仲間と一緒に、LINEグループを活性化しましょう！**

[🚀 はじめに](#-はじめに)

![猫マスコット](/readme-images/cat.webp)

</div>

---

## 📖 概要

**ReLINE**は、休眠状態のグループチャットを活性化するインテリジェントなLINE Botサービスです。かわいい猫のマスコットが魅力的なメッセージを送信します。LINEグループが一定期間非アクティブになると、Botが自動的に会話のきっかけとなるメッセージを送信し、メンバーの再参加とコミュニティの交流を促進します。

### 🎯 主な機能

- 🤖 **自動グループ監視** - グループの活動を追跡し、休眠状態を検出
- 💬 **スマートメッセージ配信** - 最適なタイミングで文脈に応じた会話のきっかけを送信
- 📊 **管理ダッシュボード** - グループの管理とエンゲージメント指標の監視
- 🔐 **セキュアな認証** - ロールベースの権限による保護された管理者アクセス
- 📱 **PWA対応** - インストール可能・オフライン対応のWebフロントエンド
- 📈 **可観測性** - ヘルスチェック / Prometheusメトリクス / 構造化ログ

---

## 🎬 使い方

![使用例](/readme-images/example.webp)

<div align="center">

### ユーザーインターフェースギャラリー

</div>

| Webランディングページ | QRコード画面 | LINEアプリ連携 |
|:---:|:---:|:---:|
| ![Webトップページ](/readme-images/web-top-page.webp) | ![QRコード](/readme-images/qr-code.webp) | ![LINEページ](/readme-images/line-page.webp) |
| マスコットと「友だち追加」ボタンのあるメインランディングページ | PC用QRコード表示 | モバイルアプリ連携画面 |

---

## 🛠 技術スタック

### バックエンド

| 技術 | バージョン | 用途 |
|------|-----------|------|
| ![Ruby](https://img.shields.io/badge/Ruby-4.0.5-CC342D?style=flat&logo=ruby&logoColor=white) | 4.0.5 | コア言語 |
| ![Rails](https://img.shields.io/badge/Rails-8.1.3-CC0000?style=flat&logo=ruby-on-rails&logoColor=white) | 8.1.3 | Webフレームワーク |
| ![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=flat&logo=mysql&logoColor=white) | 8.0+ | データベース（全環境） |
| ![LINE](https://img.shields.io/badge/LINE_Bot_API-2.x-00C300?style=flat&logo=line&logoColor=white) | 2.x | メッセージング連携 |

#### コアGems

- **認証** - Rails 8 `has_secure_password` - bcryptによるセキュアな管理者ログイン
- **認可** - `pundit` - ポリシーベースのアクセス制御
- **レート制限** - `rack-attack` - ブルートフォース攻撃対策とリクエストスロットリング
- **メッセージング** - `line-bot-api` - LINE Messaging API連携
- **監視** - `prometheus-client` - メトリクス収集と監視
- **ログ** - `lograge` + `request_store` - 相関IDつき構造化ログ

#### 開発・テスト

- **テストフレームワーク** - `rspec-rails` - 包括的なテストスイート
- **ブラウザ自動化** - `selenium-webdriver` - ヘッドレスChromeによるシステムテスト
- **コード品質** - `rubocop`（Rails、Performance、RSpec拡張付き）
- **テストデータ** - `factory_bot_rails`、`faker` - ファクトリとフィクスチャ生成
- **セキュリティ** - `brakeman`、`bundler-audit` - セキュリティ脆弱性スキャン
- **カバレッジ** - `simplecov` - `COVERAGE=true`または`CI=true`での実行時に計測し、行・ブランチともに100%を必須とする

### フロントエンド

| 技術 | 用途 |
|------|------|
| ![Bootstrap](https://img.shields.io/badge/Bootstrap-5.3.8-7952B3?style=flat&logo=bootstrap&logoColor=white) | レスポンシブUIフレームワーク |
| ![JavaScript](https://img.shields.io/badge/JavaScript-ES6+-F7DF1E?style=flat&logo=javascript&logoColor=black) | クライアントサイドインタラクティビティ |
| ![Stimulus](https://img.shields.io/badge/Stimulus-Hotwire-FF6600?style=flat) | JavaScriptフレームワーク |
| ![Turbo](https://img.shields.io/badge/Turbo-Hotwire-FF6600?style=flat) | SPA風ナビゲーション |
| ![Jest](https://img.shields.io/badge/Jest-30-C21325?style=flat&logo=jest&logoColor=white) | Service Workerモジュールのユニットテスト |

#### アセットパイプライン

- **JSバンドル** - `jsbundling-rails`（esbuild使用）
- **CSSバンドル** - `cssbundling-rails`（Bootstrap使用）
- **アセット配信** - `propshaft` - モダンなアセットパイプライン

---

## 📐 アーキテクチャ

### データベーススキーマ

![ER図](/readme-images/reline-er.webp)

### インフラストラクチャ

![インフラ構成図](/readme-images/reline-infra.webp)

### イベント処理アーキテクチャ

![LINE Botリアクションフロー](/readme-images/line-bot-reaction.webp)

イベント処理システムは、単一のエンドポイントで複数のLINE Messaging APIイベントをエレガントに処理します：

- **サービスオブジェクト** - 各イベントタイプ専用のサービスクラス
- **ストラテジーパターン** - 動的なイベントハンドラー選択
- **シンコントローラー** - 責務を委譲した最小限のコントローラーロジック
- **Rubocop準拠** - 可読性を損なうことなく厳格なスタイルガイドラインに準拠

主要なサービスは以下のとおりです。

| クラス | 責務 |
|--------|------|
| `Line::EventProcessor` | Webhookイベントのオーケストレーション |
| `Line::GroupService` | グループの参加・退出などライフサイクル管理 |
| `Line::CommandHandler` | 特殊コマンドの処理 |
| `Line::OneOnOneHandler` | 1対1トークの処理 |
| `Line::ClientAdapter` / `Line::ClientProvider` | LINE SDKの抽象化とクライアント供給 |
| `Webhooks::SignatureValidator` | 署名検証（タイミング攻撃対策付き） |
| `Resilience::RetryHandler` | 指数バックオフによるリトライ |
| `ErrorHandling::MessageSanitizer` | ログ・通知からの資格情報の除去 |

### 認証アーキテクチャ

Sorceryからの移行後、認証はRails 8標準の`has_secure_password`をベースにしたプロバイダー抽象で構成されています。

- `Authentication::Provider` - 認証プロバイダーの共通インターフェース
- `Authentication::PasswordProvider` - パスワード認証の実装
- `AuthenticationService` / `AuthResult` - 認証処理とその結果オブジェクト
- `SessionManager` - セッションの生成・失効管理
- `BruteForceProtection` - 失敗回数によるアカウントロック

### PWA

Webフロントエンドはインストール可能なPWAとして動作します。

- **Service Worker** - `app/javascript/serviceworker.js`（esbuildで`public/serviceworker.js`へバンドル）
- **キャッシュ戦略** - `cache-first` / `network-first` / `network-only` を`StrategyRouter`が振り分け
- **設定の外部化** - `config/pwa_config.yml`で環境ごとのキャッシュ戦略・マニフェストを定義し、`GET /api/pwa/config`で配信
- **マニフェスト** - `GET /manifest.json`をI18n対応で動的生成
- **オフライン表示** - `public/offline.html`
- **クライアント計測** - `POST /api/client_logs`・`POST /api/metrics`でブラウザ側のログ／メトリクスを収集

### 監視エンドポイント

| エンドポイント | 用途 |
|----------------|------|
| `GET /health` | Liveness用の軽量チェック |
| `GET /health/deep` | DB接続とディスク空き容量を含む詳細チェック |
| `GET /health/ready` | Readiness用のDB接続チェック |
| `GET /metrics` | Prometheusテキスト形式のメトリクス（本番はBasic認証） |

---

## 📊 テスト

- **RSpec** - モデル / サービス / リクエスト / システムスペックを網羅
- **SimpleCov** - `COVERAGE=true`または`CI=true`での実行時のみ計測され、行・ブランチともに100%を下回るとテストが失敗（通常の`bundle exec rspec`では計測されません）
- **Selenium** - ヘッドレスChromeによるシステムテスト
- **Jest** - Service Workerモジュール（`app/javascript/pwa/**`）のユニットテスト

テストコマンドやカバレッジ設定の詳細は[TESTING.md](TESTING.md)を参照してください。

---

## 🚀 はじめに

### 前提条件

- Docker & Docker Compose
- LINE開発者アカウント（[こちらで作成](https://developers.line.biz/)）

### 🐳 Dockerセットアップ

1. **リポジトリをクローン**

```bash
git clone https://github.com/Tsuchiya2/ReLINE.git
cd ReLINE
```

2. **環境変数と資格情報を設定**

`.env.example`をコピーして`.env`を作成します。

```bash
cp .env.example .env
```

LINEのチャネル情報やWebhookのコールバックパスはRailsの暗号化credentialsで管理します。
`config/routes.rb`が`credentials.callback_route`を参照するため、**アプリケーションを起動する前に**設定してください。

まだコンテナを起動していないため、`exec`ではなく`run --rm`でワンショット実行します。

```bash
docker compose run --rm -e EDITOR=vi web bin/rails credentials:edit
```

> すでに`docker compose up`でコンテナが起動している場合は
> `docker compose exec -e EDITOR=vi web bin/rails credentials:edit` でも編集できます。

必要なキーは以下のとおりです。

```yaml
# LINE Messaging API
channel_id: YOUR_CHANNEL_ID
channel_secret: YOUR_CHANNEL_SECRET
channel_token: YOUR_CHANNEL_TOKEN
callback_route: your_webhook_path   # POST /operator/<callback_route> になります

# db:seed で使用する初期データ
guest:
  email: guest@example.com
  password: your_guest_password
operator:
  email: operator@example.com
  password: your_operator_password
content:
  movie: https://example.com/movie
alarmcontent:
  url: https://example.com/alarm

# 本番のメール送信（config/environments/production.rb）
gmail:
  user_name: your_email@gmail.com
  password: your_app_password
```

3. **アプリケーションを起動**

```bash
docker compose up
```

これにより：
- MySQL 8.0データベースコンテナが起動
- Railsアプリケーションがビルドされ起動
- [http://localhost:3000](http://localhost:3000)でアプリが実行

4. **データベースを準備**

```bash
docker compose exec web bin/rails db:create db:schema:load
docker compose exec web bin/rails db:seed
```

**便利なDockerコマンド：**

```bash
# バックグラウンドで起動
docker compose up -d

# ログを表示
docker compose logs -f web

# Railsコンソールを実行
docker compose exec web bin/rails console

# コンテナを停止
docker compose down

# Gemfile/package.json変更後に再ビルド
docker compose build

# テストを実行
docker compose exec web bundle exec rspec

# カバレッジ付きでテストを実行
docker compose exec web bash -c "COVERAGE=true bundle exec rspec"

# システムテストのみを実行
docker compose exec web bundle exec rspec spec/system

# JavaScript（Service Worker）のテストを実行
docker compose exec web npm test

# コード品質チェック
docker compose exec web bundle exec rubocop

# セキュリティ監査
docker compose exec web bundle exec brakeman
docker compose exec web bundle exec bundler-audit

# ルートを表示
docker compose exec web bin/rails routes
```

詳細なテストコマンドとオプションは[TESTING.md](TESTING.md)を参照してください。

### ⏰ 定期実行タスク

グループへの働きかけはRakeタスクとして提供されています。cronなどのスケジューラから実行してください。

```bash
# 短いスパンでの働きかけ（Scheduler.call_notice）
docker compose exec web bin/rails call_notice:call_reminds

# 不定期な働きかけ（Scheduler.wait_notice）
docker compose exec web bin/rails wait_notice:wait_reminds
```

---

## 🎓 技術的ハイライト

### 課題：イベント駆動アーキテクチャ

最も重要な課題の1つは、LINE Messaging API向けのクリーンなイベント駆動アーキテクチャの実装でした。単一のWebhookエンドポイントが複数のイベントタイプ（メッセージ、フォロー、参加、退出など）を受信し、それぞれに異なる処理ロジックが必要でした。

**解決策：**

以下を実現するサービス指向アーキテクチャを実装しました：
- イベント処理ロジックを専用のサービスオブジェクトに分離
- サービスに委譲するシンコントローラーを維持
- 拡張性のためのポリモーフィックなイベントプロセッサを使用
- SOLIDの原則とRubocop標準に準拠

このアーキテクチャは以下を通じて進化しました：
- 経験豊富なエンジニアからのフィードバック
- 「パーフェクトRuby on Rails」のベストプラクティスの学習
- Fat ModelとFat Controllerを避けるための反復的なリファクタリング
- 厳格なRubocop準拠

---

## 📚 リソース

### プロジェクトドキュメント

- [ドキュメント一覧](docs/README.md) - `docs/`配下の案内
- [TESTING.md](TESTING.md) - テストの実行方法とカバレッジ方針
- [CHANGELOG.md](CHANGELOG.md) - 変更履歴
- [docs/MIGRATION_GUIDE.md](docs/MIGRATION_GUIDE.md) - LINE Bot SDK v2への移行手順
- [docs/observability/authentication-monitoring.md](docs/observability/authentication-monitoring.md) - 認証まわりの監視設計
- [docs/deployment/ROLLBACK.md](docs/deployment/ROLLBACK.md) - 認証移行のロールバック手順

### 外部ドキュメント

- [LINE Messaging APIドキュメント](https://developers.line.biz/ja/docs/messaging-api/)
- [Rails 8.1ガイド](https://railsguides.jp/)
- [Ruby 4.0ドキュメント](https://docs.ruby-lang.org/ja/4.0/)

---

## 🤝 コントリビューション

コントリビューションを歓迎します！お気軽にプルリクエストを送信してください。

1. リポジトリをフォーク
2. フィーチャーブランチを作成（`git checkout -b feature/amazing-feature`）
3. 変更をコミット（`git commit -m 'Add some amazing feature'`）
4. ブランチにプッシュ（`git push origin feature/amazing-feature`）
5. プルリクエストを開く

---

## 👤 作者

**Tsuchiya Yuji**

- GitHub: [@Tsuchiya2](https://github.com/Tsuchiya2)
- Qiita: [@Tsuchiya2](https://qiita.com/Tsuchiya2)
