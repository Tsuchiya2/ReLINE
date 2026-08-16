# Rollback Procedure for Rails 8 Authentication Migration

**Last Updated**: 2026-08-16

## Overview

This document describes the rollback procedure for the Rails 8 `has_secure_password` authentication migration from Sorcery gem.

> **現状**: 3フェーズすべてのマイグレーションは適用済みで、`operators`テーブルから
> `crypted_password` / `salt` は削除されています（`db/schema.rb`）。
> したがって、現時点で適用されるのは後述の **Scenario B（データベースのリストアが必要）** です。
> 本ドキュメントは移行時の手順記録として残しています。

## Pre-Deployment Checklist

Before deploying, ensure:

- [ ] Database backup completed
- [ ] All team members notified
- [ ] Monitoring dashboards open
- [ ] Rollback branch ready (previous version tagged)

## Migration Phases

The migration consists of 3 phases:

| Phase | Migration File | Can Rollback? | Timing | 状態 |
|-------|---------------|---------------|--------|------|
| 1 | `20251125141044_add_password_digest_to_operators.rb` | ✅ Yes | Deploy Day | 適用済み |
| 2 | `20251125142049_migrate_sorcery_passwords.rb` | ✅ Yes | Deploy Day | 適用済み |
| 3 | `20251125142050_remove_sorcery_columns_from_operators.rb` | ⚠️ No* | 30+ Days Later | 適用済み |

**Phase 3 removes `crypted_password` and `salt` columns permanently. Only run after confirming all operators can log in with the new system.*

---

## Rollback Triggers

Initiate rollback if ANY of the following occur:

1. **Authentication failure rate > 5%** for more than 5 minutes
2. **Login success rate drops below 90%** of baseline
3. **Account lockout rate > 10x** normal
4. **Error rate in logs > 1%** for authentication endpoints
5. **User complaints > 3** about login issues

---

## Rollback Procedures

### Scenario A: Rollback During Phase 1 or 2 (Same Day)

**Estimated Time: 15-30 minutes**

#### Step 1: Stop Traffic (2 min)
```bash
# If using load balancer, put app in maintenance mode
# Or scale down to 0 instances temporarily
```

#### Step 2: Rollback Migrations (5 min)
```bash
# SSH into production server
cd /path/to/app

# Rollback the migrations (reverse order)
RAILS_ENV=production bundle exec rails db:rollback STEP=2

# Verify rollback
RAILS_ENV=production bundle exec rails db:migrate:status
```

#### Step 3: Deploy Previous Version (10 min)
```bash
# If using Git-based deployment
git checkout v1.x.x  # Previous stable version tag
bundle install
RAILS_ENV=production bundle exec rails assets:precompile

# Restart application
sudo systemctl restart puma  # or your app server
```

#### Step 4: Verify System (5 min)
```bash
# Check health endpoints
curl https://your-app.com/health
curl https://your-app.com/health/deep

# Monitor logs for errors
tail -f log/production.log | grep -i error
```

#### Step 5: Resume Traffic
```bash
# Remove maintenance mode / scale up instances
```

---

### Scenario B: Rollback After Phase 3 (Columns Removed)

⚠️ **WARNING: This requires database restore. Data may be lost!**

**Estimated Time: 1-2 hours**

#### Step 1: Stop All Traffic Immediately
```bash
# Enable maintenance mode
```

#### Step 2: Restore Database from Backup
```bash
# Stop application
sudo systemctl stop puma

# Restore from backup (adjust for your backup system)
mysql -u root -p reline_production < /backups/pre_migration_backup.sql

# Or if using mysqldump with timestamps
mysql -u root -p reline_production < /backups/reline_production_YYYYMMDD_HHMMSS.sql
```

#### Step 3: Deploy Previous Version
```bash
git checkout v1.x.x
bundle install
RAILS_ENV=production bundle exec rails assets:precompile
sudo systemctl start puma
```

#### Step 4: Verify and Resume
```bash
# Test authentication manually
# Resume traffic when confirmed working
```

---

## Monitoring Commands

### Check Authentication Metrics
```bash
# View authentication attempts in last hour
grep "authentication" log/production.log | tail -100

# Check for errors
grep -E "(error|fail|locked)" log/production.log | tail -50

# Prometheus query (if configured)
# auth_attempts_total{status="failure"} / auth_attempts_total * 100
```

### Database Verification
```bash
RAILS_ENV=production bundle exec rails runner "
  puts 'Total operators: ' + Operator.count.to_s
  puts 'With password_digest: ' + Operator.where.not(password_digest: nil).count.to_s
  puts 'Locked accounts: ' + Operator.where('lock_expires_at > ?', Time.current).count.to_s
"
```

---

## Communication Templates

### Pre-Deployment Notice
```text
Subject: [Scheduled] Authentication System Upgrade - [DATE]

We will be upgrading our authentication system on [DATE] at [TIME].
Expected downtime: None (rolling deployment)
Impact: None expected. Please report any login issues immediately.
```

### Rollback Notice
```text
Subject: [URGENT] Authentication Rollback in Progress

We have detected issues with the new authentication system and are 
rolling back to the previous version.

Status: Rollback in progress
ETA: [TIME]
Impact: Users may experience brief login interruptions
```

### Post-Rollback Notice
```text
Subject: [Resolved] Authentication System Restored

The rollback has been completed successfully.
- All users can now log in normally
- Root cause analysis is in progress
- Next steps will be communicated within 24 hours
```

---

## Contacts

| Role | Name | Contact |
|------|------|---------|
| Primary On-Call | [Name] | [Phone/Slack] |
| Database Admin | [Name] | [Phone/Slack] |
| DevOps Lead | [Name] | [Phone/Slack] |

---

## Post-Incident Actions

After any rollback:

1. [ ] Document exact time and trigger
2. [ ] Collect relevant logs
3. [ ] Notify stakeholders
4. [ ] Schedule post-mortem within 48 hours
5. [ ] Create action items to prevent recurrence
6. [ ] Update this document if procedures need improvement

---

## Version History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2025-11-28 | 1.0 | Backend Team | Initial rollback procedure |
| 2026-08-16 | 1.1 | Backend Team | 全フェーズ適用済みであることを明記し、実装との差分を修正 |
