class ClientLog < ApplicationRecord
  VALID_LEVELS = %w[error warn info debug].freeze

  validates :level, presence: true, inclusion: { in: VALID_LEVELS }
  validates :message, presence: true

  scope :errors, -> { where(level: 'error') }
  scope :warnings, -> { where(level: 'warn') }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_trace, ->(trace_id) { where(trace_id: trace_id) }
end
