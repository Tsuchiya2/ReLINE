class Metric < ApplicationRecord
  validates :name, presence: true
  validates :value, presence: true, numericality: true

  scope :by_name, ->(name) { where(name: name) }
  scope :by_trace, ->(trace_id) { where(trace_id: trace_id) }
  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where(created_at: Time.current.all_day) }

  def self.aggregate(name)
    by_name(name).select(
      'SUM(value) as total',
      'COUNT(*) as count',
      'AVG(value) as average',
      'MIN(value) as minimum',
      'MAX(value) as maximum'
    ).take&.attributes&.symbolize_keys || {}
  end
end
