# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LineReminderJob, type: :job do
  before { stub_line_credentials }

  it '受け取った本文を順に送る' do
    allow(CatLineBot).to receive(:push_message)

    described_class.perform_now('GROUP123', %w[ひとつめ ふたつめ])

    expect(CatLineBot).to have_received(:push_message).with('GROUP123', 'ひとつめ').ordered
    expect(CatLineBot).to have_received(:push_message).with('GROUP123', 'ふたつめ').ordered
  end

  it '送信できたことを記録する' do
    allow(CatLineBot).to receive(:push_message)
    allow(PrometheusMetrics).to receive(:track_message_send)

    described_class.perform_now('GROUP123', %w[ひとつめ])

    expect(PrometheusMetrics).to have_received(:track_message_send).with('success')
  end

  context 'when 送信に失敗したとき' do
    before do
      allow(CatLineBot).to receive(:push_message).and_raise(StandardError, '送信エラー')
      allow(Rails.logger).to receive(:error)
      allow(PrometheusMetrics).to receive(:track_message_send)
    end

    it '例外を投げ直す' do
      expect { described_class.perform_now('GROUP123', %w[ひとつめ]) }
        .to raise_error(StandardError, '送信エラー')
    end

    it '失敗したことを記録する' do
      suppress(StandardError) { described_class.perform_now('GROUP123', %w[ひとつめ]) }

      expect(Rails.logger).to have_received(:error).with(/働きかけの送信に失敗しました\(GROUP123\)/)
      expect(PrometheusMetrics).to have_received(:track_message_send).with('error')
    end
  end
end
