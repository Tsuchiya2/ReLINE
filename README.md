<div align="center">

# 🐱 ReLINE - 猫メッセンジャーBot

[![Ruby](https://img.shields.io/badge/Ruby-4.0.5-CC342D?style=flat&logo=ruby&logoColor=white)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.1.3-CC0000?style=flat&logo=ruby-on-rails&logoColor=white)](https://rubyonrails.org/)
[![LINE](https://img.shields.io/badge/LINE-Messaging_API-00C300?style=flat&logo=line&logoColor=white)](https://developers.line.biz/en/services/messaging-api/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

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
- 📈 **分析とインサイト** - 会話復活の成功率を追跡

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
- **ログ** - `lograge` - 本番環境向け構造化ログ

#### 開発・テスト

- **テストフレームワーク** - `rspec-rails` - 包括的なテストスイート
- **ブラウザ自動化** - `selenium-webdriver` - ヘッドレスChromeによるシステムテスト
- **コード品質** - `rubocop`（Rails、Performance、RSpec拡張付き）
- **テストデータ** - `factory_bot_rails`、`faker` - ファクトリとフィクスチャ生成
- **セキュリティ** - `brakeman`、`bundler-audit` - セキュリティ脆弱性スキャン
- **カバレッジ** - `simplecov` - テストカバレッジ分析（88%閾値）

### フロントエンド

| 技術 | 用途 |
|------|------|
| ![Bootstrap](https://img.shields.io/badge/Bootstrap-5.3.8-7952B3?style=flat&logo=bootstrap&logoColor=white) | レスポンシブUIフレームワーク |
| ![JavaScript](https://img.shields.io/badge/JavaScript-ES6+-F7DF1E?style=flat&logo=javascript&logoColor=black) | クライアントサイドインタラクティビティ |
| ![Stimulus](https://img.shields.io/badge/Stimulus-Hotwire-FF6600?style=flat) | JavaScriptフレームワーク |
| ![Turbo](https://img.shields.io/badge/Turbo-Hotwire-FF6600?style=flat) | SPA風ナビゲーション |

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

---

## 📊 テストカバレッジ

- **モデルスペック** - ビジネスロジックの包括的なユニットテスト
- **システムスペック** - **Selenium**によるエンドツーエンド統合テスト
- **RSpec** - 主要テストフレームワーク
- **SimpleCov** - カバレッジレポート（88%閾値）
- **Selenium** - ヘッドレスChromeによるブラウザ自動化

### テストインフラストラクチャ

テストインフラストラクチャは、システムテストにSeleniumとヘッドレスChromeを使用し、以下を提供します：
- 🚀 **ヘッドレスChrome** - CI/CD環境での高速実行
- 📸 **自動スクリーンショット** - テスト失敗時にキャプチャ
- 🔄 **Capybara連携** - シームレスなRails統合
- 🌐 **クロスプラットフォーム** - 環境間で一貫した動作

詳細なテストドキュメントは[TESTING.md](TESTING.md)を参照してください。

---

## 🚀 はじめに

### 前提条件

- Docker & Docker Compose
- LINE開発者アカウント（[こちらで作成](https://developers.line.biz/)）

### 🐳 Dockerセットアップ

1. **リポジトリをクローン**

```bash
git clone https://github.com/yourusername/cat_salvages_the_relationship.git
cd cat_salvages_the_relationship
```

2. **環境変数を設定**

`.env`ファイルを作成するか、`config/credentials.yml.enc`にLINE APIキーを設定します。

3. **アプリケーションを起動**

```bash
docker compose up
```

これにより：
- MySQL 8.0データベースコンテナが起動
- Railsアプリケーションがビルドされ起動
- [http://localhost:3000](http://localhost:3000)でアプリが実行

**便利なDockerコマンド：**

```bash
# バックグラウンドで起動
docker compose up -d

# ログを表示
docker compose logs -f web

# Railsコンソールを実行
docker compose exec web bin/rails console

# テストを実行
docker compose exec web bundle exec rspec

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

# コード品質チェック
docker compose exec web bundle exec rubocop

# セキュリティ監査
docker compose exec web bundle exec brakeman
docker compose exec web bundle exec bundler-audit

# ルートを表示
docker compose exec web bin/rails routes
```

詳細なテストコマンドとオプションは[TESTING.md](TESTING.md)を参照してください。

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

### ドキュメント

- [LINE Messaging APIドキュメント](https://developers.line.biz/ja/docs/messaging-api/)
- [Rails 8.1ガイド](https://railsguides.jp/)
- [Ruby 4.0ドキュメント](https://docs.ruby-lang.org/ja/latest/)

---

## 🤝 コントリビューション

コントリビューションを歓迎します！お気軽にプルリクエストを送信してください。

1. リポジトリをフォーク
2. フィーチャーブランチを作成（`git checkout -b feature/amazing-feature`）
3. 変更をコミット（`git commit -m 'Add some amazing feature'`）
4. ブランチにプッシュ（`git push origin feature/amazing-feature`）
5. プルリクエストを開く

---

## 📄 ライセンス

このプロジェクトはMITライセンスの下でライセンスされています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

---

## 👤 作者

**Tsuchiya Yuji**

- GitHub: [@Tsuchiya2](https://github.com/Tsuchiya2)
- Qiita: [@Tsuchiy_2](https://qiita.com/Tsuchiy_2)

---

<div align="center">

**Rubyと愛情を込めて開発しました**

⭐ このリポジトリが役に立ったらスターをお願いします！

</div>
