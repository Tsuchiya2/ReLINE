class LineGroup < ApplicationRecord
  MINIMUM_MEMBER_COUNT = 2

  enum :status, { wait: 0, call: 1 }
  enum :set_span, { random: 0, faster: 1, latter: 2 }

  validates :line_group_id, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :remind_at,     presence: true
  validates :status,        presence: true
  validates :post_count,    presence: true, numericality: { only_integer: true,
                                                            greater_than_or_equal_to: 0,
                                                            less_than_or_equal_to: 1_000_000_000 }
  validates :member_count,  presence: true, numericality: { only_integer: true,
                                                            greater_than_or_equal_to: 0,
                                                            less_than_or_equal_to: 50 }
  validates :set_span,      presence: true

  scope :remind_wait, -> { wait.where('remind_at <= ?', Date.current) }
  scope :remind_call, -> { call.where('remind_at <= ?', Date.current) }

  def self.find_or_create_from_line!(line_group_id, member_count)
    return if member_count < MINIMUM_MEMBER_COUNT

    find_or_create_by!(line_group_id: line_group_id) do |line_group|
      line_group.remind_at = Date.current.tomorrow
      line_group.status = :wait
      line_group.member_count = member_count
    end
  end

  def update_record(member_count)
    random_number = if faster?
                      (21..32).to_a.sample
                    elsif latter?
                      (49..60).to_a.sample
                    else
                      (17..60).to_a.sample
                    end
    update!(remind_at: Date.current.since(random_number.days),
            status: :wait, post_count: post_count + 1,
            member_count: member_count)
  end
end
