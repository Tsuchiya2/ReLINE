# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrometheusMetrics do
  let(:event) { Line::Bot::V2::Webhook::LeaveEvent }

  describe '.track_webhook_request' do
    it 'Webhook リクエストの結果を数える' do
      expect { described_class.track_webhook_request('success') }
        .to change { WEBHOOK_REQUESTS_TOTAL.get(labels: { status: 'success' }) }.by(1)
    end
  end

  describe '.track_event' do
    it 'イベントの処理結果を種類ごとに数える' do
      labels = { event_type: event.name, status: 'success' }

      expect { described_class.track_event(event.allocate, 'success') }
        .to change { EVENT_PROCESSED_TOTAL.get(labels: labels) }.by(1)
    end
  end

  describe '.track_event_duration' do
    it 'イベントの処理時間を記録する' do
      expect { described_class.track_event_duration(event.allocate, 0.5) }
        .to change { WEBHOOK_DURATION.get(labels: { event_type: event.name })['sum'] }.by(0.5)
    end
  end

  describe '.track_line_api_call' do
    it '呼び出し回数を数える' do
      labels = { method: 'push_message', status: '200' }

      expect { described_class.track_line_api_call('push_message', 200, 0.1) }
        .to change { LINE_API_CALLS_TOTAL.get(labels: labels) }.by(1)
    end

    it '所要時間を記録する' do
      expect { described_class.track_line_api_call('reply_message', 200, 0.25) }
        .to change { LINE_API_DURATION.get(labels: { method: 'reply_message' })['sum'] }.by(0.25)
    end
  end

  describe '.track_message_send' do
    it 'メッセージ送信の結果を数える' do
      expect { described_class.track_message_send('success') }
        .to change { MESSAGE_SEND_TOTAL.get(labels: { status: 'success' }) }.by(1)
    end
  end

  describe '.track_authentication' do
    it '認証の試行回数を数える' do
      labels = { provider: described_class::PASSWORD_PROVIDER, result: :success }

      expect { described_class.track_authentication(:success) }
        .to change { AUTH_ATTEMPTS_TOTAL.get(labels: labels) }.by(1)
    end

    it '認証にかかった時間を記録する' do
      labels = { provider: described_class::PASSWORD_PROVIDER }

      expect { described_class.track_authentication(:success, duration: 0.2) }
        .to change { AUTH_DURATION.get(labels: labels)['sum'] }.by(0.2)
    end

    it '失敗理由ごとに数える' do
      labels = { provider: described_class::PASSWORD_PROVIDER, reason: :invalid_credentials }

      expect { described_class.track_authentication(:failed, reason: :invalid_credentials) }
        .to change { AUTH_FAILURES_TOTAL.get(labels: labels) }.by(1)
    end

    it 'ロックされた回数を別に数える' do
      labels = { provider: described_class::PASSWORD_PROVIDER }

      expect { described_class.track_authentication(:failed, reason: :account_locked) }
        .to change { AUTH_LOCKED_ACCOUNTS_TOTAL.get(labels: labels) }.by(1)
    end
  end

  describe '.update_group_count' do
    it 'グループ数を最新の値にする' do
      described_class.update_group_count(7)

      expect(LINE_GROUPS_TOTAL.get).to eq(7)
    end
  end
end
