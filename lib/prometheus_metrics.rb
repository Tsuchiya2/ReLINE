module PrometheusMetrics
  PASSWORD_PROVIDER = 'password'.freeze

  class << self
    def track_webhook_request(status)
      WEBHOOK_REQUESTS_TOTAL.increment(labels: { status: status })
    end

    def track_event_duration(event, duration)
      WEBHOOK_DURATION.observe(duration, labels: { event_type: event.class.name })
    end

    def track_event(event, status)
      EVENT_PROCESSED_TOTAL.increment(labels: { event_type: event.class.name, status: status })
    end

    def track_line_api_call(method, status, duration)
      LINE_API_CALLS_TOTAL.increment(labels: { method: method, status: status.to_s })
      LINE_API_DURATION.observe(duration, labels: { method: method })
    end

    def track_message_send(status)
      MESSAGE_SEND_TOTAL.increment(labels: { status: status })
    end

    def track_authentication(result, reason: nil, duration: nil)
      AUTH_ATTEMPTS_TOTAL.increment(labels: { provider: PASSWORD_PROVIDER, result: result })
      AUTH_DURATION.observe(duration, labels: { provider: PASSWORD_PROVIDER }) if duration

      return if reason.blank?

      AUTH_FAILURES_TOTAL.increment(labels: { provider: PASSWORD_PROVIDER, reason: reason })
      AUTH_LOCKED_ACCOUNTS_TOTAL.increment(labels: { provider: PASSWORD_PROVIDER }) if reason == :account_locked
    end

    def update_group_count(count)
      LINE_GROUPS_TOTAL.set(count)
    end
  end
end
