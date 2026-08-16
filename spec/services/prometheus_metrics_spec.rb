# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrometheusMetrics do
  # Each tracking method is guarded by `return unless defined?(METRIC_CONSTANT)`.
  # The metric constants are defined globally in config/initializers/prometheus.rb,
  # so the "defined" branch runs in the normal test environment. `hide_const`
  # exercises the early-return branch when the constant is undefined.

  let(:event) { double('LineEvent') }

  describe '.track_webhook_duration' do
    it 'observes the duration when the metric is defined' do
      expect(WEBHOOK_DURATION).to receive(:observe).with(1.5, labels: { event_type: 'message' })

      described_class.track_webhook_duration('message', 1.5)
    end

    it 'returns nil when the metric is undefined' do
      hide_const('WEBHOOK_DURATION')
      expect(described_class.track_webhook_duration('message', 1.5)).to be_nil
    end
  end

  describe '.track_webhook_request' do
    it 'increments the counter when the metric is defined' do
      expect(WEBHOOK_REQUESTS_TOTAL).to receive(:increment).with(labels: { status: 'success' })

      described_class.track_webhook_request('success')
    end

    it 'returns nil when the metric is undefined' do
      hide_const('WEBHOOK_REQUESTS_TOTAL')
      expect(described_class.track_webhook_request('success')).to be_nil
    end
  end

  describe '.track_event_success' do
    it 'increments the counter with success status when the metric is defined' do
      expect(EVENT_PROCESSED_TOTAL).to receive(:increment).with(
        labels: { event_type: event.class.name, status: 'success' }
      )

      described_class.track_event_success(event)
    end

    it 'returns nil when the metric is undefined' do
      hide_const('EVENT_PROCESSED_TOTAL')
      expect(described_class.track_event_success(event)).to be_nil
    end
  end

  describe '.track_event_failure' do
    it 'increments the counter with error status when the metric is defined' do
      expect(EVENT_PROCESSED_TOTAL).to receive(:increment).with(
        labels: { event_type: event.class.name, status: 'error' }
      )

      described_class.track_event_failure(event, StandardError.new('boom'))
    end

    it 'returns nil when the metric is undefined' do
      hide_const('EVENT_PROCESSED_TOTAL')
      expect(described_class.track_event_failure(event, StandardError.new('boom'))).to be_nil
    end
  end

  describe '.track_line_api_call' do
    it 'records the call and duration when both metrics are defined' do
      expect(LINE_API_CALLS_TOTAL).to receive(:increment).with(labels: { method: 'push', status: '200' })
      expect(LINE_API_DURATION).to receive(:observe).with(0.3, labels: { method: 'push' })

      described_class.track_line_api_call('push', '200', 0.3)
    end

    it 'returns nil when a required metric is undefined' do
      hide_const('LINE_API_DURATION')
      expect(described_class.track_line_api_call('push', '200', 0.3)).to be_nil
    end
  end

  describe '.track_message_send' do
    it 'increments the counter when the metric is defined' do
      expect(MESSAGE_SEND_TOTAL).to receive(:increment).with(labels: { status: 'success' })

      described_class.track_message_send('success')
    end

    it 'returns nil when the metric is undefined' do
      hide_const('MESSAGE_SEND_TOTAL')
      expect(described_class.track_message_send('success')).to be_nil
    end
  end

  describe '.track_authentication' do
    let(:provider) { described_class::PASSWORD_PROVIDER }

    it 'increments the attempt counter when the metric is defined' do
      expect(AUTH_ATTEMPTS_TOTAL).to receive(:increment).with(labels: { provider: provider, result: :success })

      described_class.track_authentication(:success)
    end

    it 'observes the duration when it is given' do
      allow(AUTH_ATTEMPTS_TOTAL).to receive(:increment)
      expect(AUTH_DURATION).to receive(:observe).with(0.2, labels: { provider: provider })

      described_class.track_authentication(:success, duration: 0.2)
    end

    it 'increments the failure counter with the reason' do
      allow(AUTH_ATTEMPTS_TOTAL).to receive(:increment)
      expect(AUTH_FAILURES_TOTAL).to receive(:increment).with(
        labels: { provider: provider, reason: :invalid_credentials }
      )

      described_class.track_authentication(:failed, reason: :invalid_credentials)
    end

    it 'counts locked accounts separately' do
      allow(AUTH_ATTEMPTS_TOTAL).to receive(:increment)
      allow(AUTH_FAILURES_TOTAL).to receive(:increment)
      expect(AUTH_LOCKED_ACCOUNTS_TOTAL).to receive(:increment).with(labels: { provider: provider })

      described_class.track_authentication(:failed, reason: :account_locked)
    end

    it 'returns nil when the metric is undefined' do
      hide_const('AUTH_ATTEMPTS_TOTAL')
      expect(described_class.track_authentication(:success)).to be_nil
    end
  end

  describe '.update_group_count' do
    it 'sets the gauge when the metric is defined' do
      expect(LINE_GROUPS_TOTAL).to receive(:set).with(42)

      described_class.update_group_count(42)
    end

    it 'returns nil when the metric is undefined' do
      hide_const('LINE_GROUPS_TOTAL')
      expect(described_class.update_group_count(42)).to be_nil
    end
  end
end
