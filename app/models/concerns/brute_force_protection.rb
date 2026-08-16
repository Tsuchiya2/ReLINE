module BruteForceProtection
  extend ActiveSupport::Concern

  included do
    class_attribute :lock_retry_limit, default: ENV.fetch('LOCK_RETRY_LIMIT', 5).to_i
    class_attribute :lock_duration, default: ENV.fetch('LOCK_DURATION', 45).to_i.minutes
    class_attribute :lock_notifier, default: nil
  end

  def increment_failed_logins!
    increment!(:failed_logins_count) # rubocop:disable Rails/SkipsModelValidations
    lock_account! if failed_logins_count >= lock_retry_limit
  end

  def reset_failed_logins!
    # rubocop:disable Rails/SkipsModelValidations
    update_columns(
      failed_logins_count: 0,
      lock_expires_at: nil,
      updated_at: Time.current
    )
    # rubocop:enable Rails/SkipsModelValidations
  end

  def lock_account!
    # rubocop:disable Rails/SkipsModelValidations
    update_columns(
      lock_expires_at: Time.current + lock_duration,
      unlock_token: SecureRandom.urlsafe_base64(32),
      updated_at: Time.current
    )
    # rubocop:enable Rails/SkipsModelValidations
  end

  def unlock_account!
    # rubocop:disable Rails/SkipsModelValidations
    update_columns(
      lock_expires_at: nil,
      unlock_token: nil,
      failed_logins_count: 0,
      updated_at: Time.current
    )
    # rubocop:enable Rails/SkipsModelValidations
  end

  def locked?
    lock_expires_at.present? && lock_expires_at > Time.current
  end

  def mail_notice(ip_address)
    lock_notifier&.call(self, ip_address)
  end
end
