# LINE Bot SDK Modernization - Migration Guide

## Overview

This guide explains the migration from the legacy `CatLineBot` implementation to the new service-oriented architecture using LINE Bot SDK v2.x.

**Migration Date**: 2025-11-17
**Rails Version at migration**: 8.1.1（現在: 8.1.3）
**Ruby Version at migration**: 3.4.6（現在: 4.0.5）
**Last Reviewed**: 2026-08-16

---

## What Changed

### Architecture

**Before (Legacy)**:
```
LINE Webhook → WebhooksController → CatLineBot (God Object) → LINE SDK v1.x
```

**After (New)**:
```
LINE Webhook → WebhooksController → EventProcessor
                                    ├─ ClientAdapter (abstraction)
                                    ├─ GroupService (business logic)
                                    ├─ CommandHandler (commands)
                                    └─ OneOnOneHandler (1-on-1 chats)
```

### Key Improvements

1. **Service-Oriented Architecture**: Separated concerns into focused services
2. **Observability**: Added Prometheus metrics and health check endpoints
3. **Reliability**: Retry logic, transaction management, timeout protection
4. **Security**: Error message sanitization prevents credential leakage
5. **Testability**: Dependency injection makes testing easier

---

## Breaking Changes

**None** - This migration is 100% backward compatible:
- Same webhook endpoint: `POST /operator/<callback_route>`（パスは`Rails.application.credentials.callback_route`で定義）
- Same business logic (join, leave, commands)
- Same database schema
- Same scheduler behavior

---

## New Features

### 1. Health Check Endpoints

```bash
# Shallow health check (fast) - liveness
GET /health
# Response: {
#   "status": "ok",
#   "timestamp": "2026-08-16T10:00:00+09:00",
#   "version": "CatSalvagesTheRelationship"
# }

# Deep health check (verifies dependencies)
GET /health/deep
# Response (200 / 503):
# {
#   "status": "ok",
#   "timestamp": "2026-08-16T10:00:00+09:00",
#   "checks": {
#     "database":   { "status": "ok", "response_time_ms": 2.34 },
#     "disk_space": { "status": "ok", "usage_percent": 42 }
#   }
# }
# いずれかのチェックが "ok" 以外なら status は "degraded" となり 503 を返します。

# Readiness check (database connectivity only)
GET /health/ready
# Response (200): { "status": "ready", "timestamp": "..." }
# Response (503): { "status": "not_ready", "reason": "database_unavailable" }
```

> `GET /health/ready` は Rails 8 認証移行（2025-11-26）で追加されました。

### 2. Metrics Endpoint

```bash
# Prometheus metrics
GET /metrics

# Example metrics:
# webhook_requests_total{status="success"} 1234
# line_api_calls_total{method="push_message",status="success"} 567
# line_groups_total 42
```

本番環境では`MONITOR_USERNAME` / `MONITOR_PASSWORD`によるBasic認証が必要です。
どちらか一方でも未設定の場合、`/metrics`は403を返します。

### 3. Structured Logging

All logs are now in JSON format with correlation IDs:

```json
{
  "timestamp": "2025-11-17T10:00:00+09:00",
  "correlation_id": "abc123",
  "group_id": "GROUP456",
  "event_type": "message",
  "duration_ms": 123,
  "status": "success"
}
```

---

## Code Changes

### Removed Files

```
app/models/cat_line_bot.rb  (deleted)
app/models/concerns/message_event.rb  (deleted)
```

### New Files

**Services**:
- `app/services/line/event_processor.rb` - Core webhook processing
- `app/services/line/group_service.rb` - Group lifecycle management
- `app/services/line/command_handler.rb` - Special command processing
- `app/services/line/one_on_one_handler.rb` - 1-on-1 chat handling
- `app/services/line/client_adapter.rb` - LINE SDK abstraction
- `app/services/line/client_provider.rb` - Client instance provider
- `app/services/line/member_counter.rb` - Member counting utility

**Utilities**:
- `app/services/webhooks/signature_validator.rb` - Signature verification
- `app/services/resilience/retry_handler.rb` - Retry logic
- `app/services/error_handling/message_sanitizer.rb` - Error sanitization
- `app/services/prometheus_metrics.rb` - Metrics tracking

**Controllers**:
- `app/controllers/health_controller.rb` - Health checks
- `app/controllers/metrics_controller.rb` - Prometheus metrics

### Updated Files

- `app/controllers/operator/webhooks_controller.rb` - Uses EventProcessor
- `app/models/scheduler.rb` - Uses ClientProvider
- `config/routes.rb` - Added /health, /health/deep and /metrics（/health/ready は後続の認証移行で追加）
- `Gemfile` - Updated dependencies

---

## Configuration Changes

### 1. Gemfile

```ruby
# Before
gem 'line-bot-api', '~> 1.x'

# After
gem 'line-bot-api', '~> 2.0'
gem 'prometheus-client', '~> 4.0'
gem 'lograge', '~> 0.14'
gem 'request_store', '~> 1.5'
```

### 2. Initializers

**New files**:
- `config/initializers/lograge.rb` - Structured logging
- `config/initializers/prometheus.rb` - Metrics definitions

### 3. Credentials

No changes required - same structure:
```yaml
channel_id: YOUR_CHANNEL_ID
channel_secret: YOUR_CHANNEL_SECRET
channel_token: YOUR_CHANNEL_TOKEN
callback_route: your_webhook_path
operator:
  email: your-email@example.com
```

credentialsに必要な全キーは[README.md](../README.md)を参照してください。

---

## Deployment Steps

### 1. Pre-Deployment

```bash
# 1. Verify current version works
bundle exec rspec
bundle exec rubocop

# 2. Backup database（mysqldump などお使いのバックアップ手段で）
mysqldump -u root -p reline_production > backup_$(date +%Y%m%d_%H%M%S).sql

# 3. Install new dependencies
bundle install
```

### 2. Zero-Downtime Deployment

```bash
# 1. Deploy new code
git pull origin main

# 2. Run database migrations (if any)
bundle exec rake db:migrate

# 3. Restart application (rolling restart recommended)
# Heroku:
heroku restart

# Systemd:
sudo systemctl reload your-app

# Docker:
docker compose up -d --no-deps --build web
```

### 3. Post-Deployment Verification

```bash
# 1. Check health
curl https://your-app.com/health/deep

# 2. Verify metrics endpoint
curl https://your-app.com/metrics

# 3. Send test webhook (from LINE Developers Console)
# 4. Check logs for JSON format
tail -f log/production.log
```

---

## Monitoring Setup

### Prometheus Configuration

```yaml
scrape_configs:
  - job_name: 'line-bot'
    static_configs:
      - targets: ['your-app.com:443']
    metrics_path: '/metrics'
    scheme: 'https'
    scrape_interval: 30s
```

### Key Metrics to Monitor

```promql
# Success rate
rate(webhook_requests_total{status="success"}[5m])

# Error rate (alert if > 5%)
rate(webhook_requests_total{status="error"}[5m]) > 0.05

# P95 latency (alert if > 5s)
histogram_quantile(0.95, webhook_duration_seconds_bucket) > 5
```

---

## Rollback Procedure

If issues occur, rollback is simple:

```bash
# 1. Revert to previous version
git revert HEAD
git push origin main

# 2. Redeploy
# (same deployment steps as above)

# 3. Verify
curl https://your-app.com/health
```

**Note**: No database changes were made, so no migration rollback needed.

---

## Testing

### Running Tests

```bash
# All tests
bundle exec rspec

# Specific suites
bundle exec rspec spec/services/
bundle exec rspec spec/controllers/

# With coverage
COVERAGE=true bundle exec rspec
```

### Test Coverage Goals

`spec/rails_helper.rb`のSimpleCov設定により、行・ブランチともに **100%** が必須です
（`COVERAGE=true`または`CI=true`のときに計測・判定されます）。詳細は[TESTING.md](../TESTING.md)を参照してください。

---

## Troubleshooting

### Issue: Health check returns 503

**Cause**: `GET /health/deep`はデータベース接続とディスク空き容量をチェックします。
どちらかが`ok`でない場合に503（`"status": "degraded"`）を返します。
`GET /health/ready`はデータベース接続のみをチェックします。

**Solution**:
```bash
# レスポンスの checks を見て、どちらが失敗しているか確認
curl -s https://your-app.com/health/deep | jq

# データベース
rails db:migrate:status

# ディスク空き容量（使用率90%以上で warning）
df -h /
```

### Issue: Metrics endpoint returns empty

**Cause**: No webhooks processed yet

**Solution**: Send a test webhook from LINE Developers Console

### Issue: Logs not in JSON format

**Cause**: Lograge not initialized

**Solution**:
```bash
# Verify initializer exists
ls config/initializers/lograge.rb

# Restart application
```

---

## Support

- GitHub Issues: https://github.com/Tsuchiya2/ReLINE/issues
- 設計ドキュメント: [docs/designs/line-sdk-modernization.md](designs/line-sdk-modernization.md)
- ドキュメント索引: [docs/README.md](README.md)

---

**Migration completed successfully** ✅
