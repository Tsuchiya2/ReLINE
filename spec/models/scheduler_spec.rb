# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scheduler, type: :model do
  describe '.call_messages' do
    let(:sampler) { instance_double(Line::AlarmContentSampler) }

    before do
      allow(sampler).to receive(:available?).and_return(true, true)
    end

    it 'falls back when body is missing' do
      allow(sampler).to receive(:sample).and_return(nil)

      messages = described_class.call_messages(sampler)
      expect(messages[0][:text]).to eq('管理者へ連絡お願いします。')
      expect(messages[1][:text]).to eq('呼びかけメッセージを用意できなかったニャ…🐱')
    end
  end

  describe '.wait_messages' do
    let(:sampler) { instance_double(Line::ContentSampler) }

    before do
      allow(sampler).to receive(:available?).and_return(true, true, true)
    end

    it 'returns sample bodies when present' do
      allow(sampler).to receive(:sample).and_return(
        double(body: 'contact'),
        double(body: 'free'),
        double(body: 'text')
      )

      messages = described_class.wait_messages(sampler)
      expect(messages.map { |m| m[:text] }).to eq(%w[contact free text])
    end

    it 'uses fallbacks when samples are nil' do
      allow(sampler).to receive(:sample).and_return(nil, nil, nil)

      messages = described_class.wait_messages(sampler)
      expect(messages[0][:text]).to eq('いつでも声をかけてニャ！')
      expect(messages[1][:text]).to eq('今日はどんな一日だった？')
      expect(messages[2][:text]).to eq('もう少し仲良くなりたいニャ🐾')
    end
  end

  describe '.scheduler' do
    let(:sampler) { instance_double(Line::ContentSampler) }
    let(:group) { create(:line_group) }

    before do
      # Mock Rails credentials to prevent ApplicationMailer initialization error
      allow(Rails.application).to receive(:credentials).and_return(
        double(operator: { email: 'test@example.com' })
      )
    end

    it 'sends error email when required content is missing' do
      allow(sampler).to receive(:available?).and_return(false, true, true)
      allow(LineMailer).to receive(:error_email).and_return(double(deliver_later: true))
      allow(PrometheusMetrics).to receive(:track_message_send)

      described_class.scheduler(LineGroup.where(id: group.id), sampler, :wait)

      expect(LineMailer).to have_received(:error_email).with(group.line_group_id, /コンテンツ未登録/)
      expect(PrometheusMetrics).to have_received(:track_message_send).with('error')
    end

    context 'when a group is processed successfully' do
      let(:group) { create(:line_group, status: :wait) }

      before do
        allow(Rails.application).to receive(:credentials).and_return(
          double(operator: { email: 'test@example.com' })
        )
        allow(sampler).to receive_messages(available?: true, sample: double(body: 'message body'))
        allow(Line::ReminderJob).to receive(:perform_later)
        allow(PrometheusMetrics).to receive(:track_message_send)
      end

      it 'moves the group to call status and enqueues a reminder job' do
        described_class.scheduler(LineGroup.where(id: group.id), sampler, :wait)

        expect(group.reload.status).to eq('call')
        expect(Line::ReminderJob).to have_received(:perform_later)
          .with(group.line_group_id, kind_of(Array))
      end
    end
  end

  describe '.call_notice' do
    it 'schedules call reminders for groups due for a call' do
      allow(LineGroup).to receive(:remind_call).and_return(:remind_groups)
      allow(described_class).to receive(:initialize_alarm_sampler).and_return(:sampler)
      allow(described_class).to receive(:scheduler)

      described_class.call_notice

      expect(described_class).to have_received(:scheduler).with(:remind_groups, :sampler, :call)
    end
  end

  describe '.wait_notice' do
    it 'schedules wait reminders for groups due for a wait' do
      allow(LineGroup).to receive(:remind_wait).and_return(:remind_groups)
      allow(described_class).to receive(:initialize_content_sampler).and_return(:sampler)
      allow(described_class).to receive(:scheduler)

      described_class.wait_notice

      expect(described_class).to have_received(:scheduler).with(:remind_groups, :sampler, :wait)
    end
  end

  describe '.initialize_alarm_sampler' do
    it 'preloads and returns an alarm content sampler' do
      sampler = instance_double(Line::AlarmContentSampler)
      allow(Line::AlarmContentSampler).to receive(:new).and_return(sampler)
      allow(sampler).to receive(:preload_all)

      expect(described_class.initialize_alarm_sampler).to eq(sampler)
      expect(sampler).to have_received(:preload_all)
    end
  end

  describe '.initialize_content_sampler' do
    it 'preloads and returns a content sampler' do
      sampler = instance_double(Line::ContentSampler)
      allow(Line::ContentSampler).to receive(:new).and_return(sampler)
      allow(sampler).to receive(:preload_all)

      expect(described_class.initialize_content_sampler).to eq(sampler)
      expect(sampler).to have_received(:preload_all)
    end
  end

  describe '.build_messages' do
    it 'builds call messages for the :call notice type' do
      sampler = instance_double(Line::AlarmContentSampler)
      allow(sampler).to receive_messages(available?: true, sample: double(body: 'x'))

      expect(described_class.build_messages(sampler, :call).size).to eq(2)
    end

    it 'raises ArgumentError for an unknown notice type' do
      expect { described_class.build_messages(double, :unknown) }
        .to raise_error(ArgumentError, 'Unknown notice type: unknown')
    end
  end
end
