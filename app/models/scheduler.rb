class Scheduler
  NEXT_REMIND_DAYS = (1..3)

  class << self
    def call_notice
      notice(LineGroup.remind_call, AlarmContent.bodies_by_category, %i[contact text])
    end

    def wait_notice
      notice(LineGroup.remind_wait, Content.bodies_by_category, %i[contact free text])
    end

    private

    def notice(line_groups, bodies, categories)
      line_groups.find_each do |line_group|
        LineReminderJob.perform_later(line_group.line_group_id, sample_bodies(bodies, categories))
        line_group.update!(remind_at: Date.current.since(NEXT_REMIND_DAYS.to_a.sample.days), status: :call)
      rescue StandardError => e
        report_scheduler_errors(e, line_group)
      end
    end

    def sample_bodies(bodies, categories)
      categories.map do |category|
        body = bodies[category]&.sample
        raise "働きかけの文面が登録されていません(#{category})" if body.blank?

        body
      end
    end

    def report_scheduler_errors(exception, line_group)
      error_message = ErrorSanitizer.format(exception, 'Scheduler')
      Rails.logger.error(error_message)
      LineMailer.error_email(line_group.line_group_id, error_message).deliver_later
      PrometheusMetrics.track_message_send('error')
    end
  end
end
