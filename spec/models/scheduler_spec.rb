# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scheduler, type: :model do
  before { stub_line_credentials }

  describe '.call_notice' do
    let!(:line_group) { create(:line_group, status: :call, remind_at: Date.current) }

    before do
      create(:alarm_content, category: :contact, body: '連絡してほしいニャ')
      create(:alarm_content, category: :text, body: '起きてるニャ？')
    end

    it '対象のグループへ働きかけを予約する' do
      expect { described_class.call_notice }
        .to have_enqueued_job(LineReminderJob)
        .with(line_group.line_group_id, ['連絡してほしいニャ', '起きてるニャ？'])
    end

    it '次に働きかける日を先送りする' do
      described_class.call_notice

      expect(line_group.reload.remind_at).to be > Date.current
    end

    it '働きかける日がまだ先のグループは対象にしない' do
      line_group.update!(remind_at: Date.current.tomorrow)

      expect { described_class.call_notice }.not_to have_enqueued_job(LineReminderJob)
    end
  end

  describe '.wait_notice' do
    let!(:line_group) { create(:line_group, status: :wait, remind_at: Date.current) }

    before do
      create(:content, category: :contact, body: '元気ニャ？')
      create(:content, category: :free, body: '今日はいい天気ニャ')
      create(:content, category: :text, body: 'また話そうニャ')
    end

    it 'カテゴリの順に文面を並べて働きかけを予約する' do
      expect { described_class.wait_notice }
        .to have_enqueued_job(LineReminderJob)
        .with(line_group.line_group_id, ['元気ニャ？', '今日はいい天気ニャ', 'また話そうニャ'])
    end

    it '働きかけたグループを call 状態にする' do
      described_class.wait_notice

      expect(line_group.reload.status).to eq('call')
    end
  end

  describe '文面が足りないとき' do
    let!(:line_group) { create(:line_group, status: :wait, remind_at: Date.current) }

    before do
      create(:content, category: :contact, body: '元気ニャ？')
      allow(LineMailer).to receive(:error_email).and_return(double(deliver_later: true))
      allow(Rails.logger).to receive(:error)
    end

    it '運用者へ通知する' do
      described_class.wait_notice

      expect(LineMailer).to have_received(:error_email)
        .with(line_group.line_group_id, /働きかけの文面が登録されていません\(free\)/)
    end

    it '働きかけは予約しない' do
      expect { described_class.wait_notice }.not_to have_enqueued_job(LineReminderJob)
    end

    it '失敗したことを記録する' do
      allow(PrometheusMetrics).to receive(:track_message_send)

      described_class.wait_notice

      expect(PrometheusMetrics).to have_received(:track_message_send).with('error')
    end
  end
end
