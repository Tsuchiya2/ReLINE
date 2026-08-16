class Operator < ApplicationRecord
  has_secure_password
  include BruteForceProtection

  enum :role, { operator: 0, guest: 1 }

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  self.lock_retry_limit = ENV.fetch('OPERATOR_LOCK_RETRY_LIMIT', 5).to_i
  self.lock_duration = ENV.fetch('OPERATOR_LOCK_DURATION', 45).to_i.minutes
  self.lock_notifier = ->(record, ip) { SessionMailer.notice(record, ip).deliver_later }

  PASSWORD_COMPLEXITY_REGEX = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+\z/

  validates :name,                    presence: true, length: { in: 2..255 }
  validates :email,                   presence: true, uniqueness: true
  validates :email,                   format: { with: /\A[a-z0-9_-]+@[a-z0-9_-]+\.[a-z0-9_-]+\z/ }
  validates :password,                presence: true, on: :create
  validates :password,                length: { minimum: 8 }, if: -> { password.present? }
  validates :password,                format: {
    with: PASSWORD_COMPLEXITY_REGEX,
    message: I18n.t(
      'activerecord.errors.models.operator.attributes.password.complexity',
      default: 'must include at least one lowercase letter, one uppercase letter, and one digit'
    )
  }, if: -> { password.present? }
  validates :password,                confirmation: true, if: -> { password.present? }
  validates :password_confirmation,   presence: true, if: -> { password.present? }
  validates :role,                    presence: true
end
