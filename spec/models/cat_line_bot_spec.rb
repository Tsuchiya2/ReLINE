# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatLineBot, type: :model do
  let(:client) { instance_double(Line::Bot::V2::MessagingApi::ApiClient) }

  before do
    stub_line_credentials
    allow(described_class).to receive(:client).and_return(client)
  end

  describe '.line_bot_action' do
    it 'イベントを 1 件ずつ処理する' do
      allow(described_class).to receive(:parse_event)
      events = [line_message_event, line_join_event]

      described_class.line_bot_action(events)

      expect(described_class).to have_received(:parse_event).twice
    end

    it '1 件が失敗しても後続を処理し、運用者へ通知する' do
      failing_event = line_message_event
      allow(described_class).to receive(:parse_event).with(failing_event).and_raise(StandardError, 'エラー')
      allow(described_class).to receive(:parse_event).with(an_instance_of(Line::Bot::V2::Webhook::JoinEvent))
      allow(LineMailer).to receive(:error_email).and_return(double(deliver_later: true))
      allow(PrometheusMetrics).to receive(:track_event)

      described_class.line_bot_action([failing_event, line_join_event])

      expect(LineMailer).to have_received(:error_email).with('GROUP123', /エラー/)
      expect(PrometheusMetrics).to have_received(:track_event).with(failing_event, 'error')
    end

    it '通知するメッセージからチャネル情報を伏せる' do
      event = line_message_event
      allow(described_class).to receive(:parse_event).and_raise(StandardError, 'channel_token: secret-value')
      allow(LineMailer).to receive(:error_email).and_return(double(deliver_later: true))

      described_class.line_bot_action([event])

      expect(LineMailer).to have_received(:error_email).with('GROUP123', /\[REDACTED\]/)
    end
  end

  describe '.parse_event' do
    it '1対1トークのイベントは one_on_one へ渡す' do
      event = line_message_event(source: line_user_source)
      allow(described_class).to receive(:one_on_one)

      described_class.parse_event(event)

      expect(described_class).to have_received(:one_on_one).with(event)
    end

    it 'グループのイベントは種類ごとの処理へ渡す' do
      event = line_message_event
      allow(described_class).to receive_messages(count_members: 5, action_by_event_type: nil)

      described_class.parse_event(event)

      expect(described_class).to have_received(:action_by_event_type).with(event, 'GROUP123', 5)
    end

    it '処理した件数と時間を記録する' do
      event = line_message_event(source: line_user_source)
      allow(described_class).to receive(:one_on_one)
      allow(PrometheusMetrics).to receive(:track_event)
      allow(PrometheusMetrics).to receive(:track_event_duration)

      described_class.parse_event(event)

      expect(PrometheusMetrics).to have_received(:track_event).with(event, 'success')
      expect(PrometheusMetrics).to have_received(:track_event_duration).with(event, kind_of(Float))
    end
  end

  describe '.current_group_id' do
    it 'グループからのイベントはグループ ID を返す' do
      expect(described_class.current_group_id(line_message_event)).to eq('GROUP123')
    end

    it 'トークルームからのイベントはルーム ID を返す' do
      event = line_message_event(source: line_room_source)

      expect(described_class.current_group_id(event)).to eq('ROOM123')
    end

    it '1対1トークのイベントは nil を返す' do
      event = line_message_event(source: line_user_source)

      expect(described_class.current_group_id(event)).to be_nil
    end
  end

  describe '.count_members' do
    it 'グループの人数を LINE へ問い合わせる' do
      allow(client).to receive(:get_group_member_count_with_http_info)
        .with(group_id: 'GROUP123')
        .and_return([Line::Bot::V2::MessagingApi::GroupMemberCountResponse.new(count: 5), 200, {}])

      expect(described_class.count_members(line_message_event)).to eq(5)
    end

    it 'トークルームの人数を LINE へ問い合わせる' do
      allow(client).to receive(:get_room_member_count_with_http_info)
        .with(room_id: 'ROOM123')
        .and_return([Line::Bot::V2::MessagingApi::RoomMemberCountResponse.new(count: 3), 200, {}])

      expect(described_class.count_members(line_message_event(source: line_room_source))).to eq(3)
    end

    it '1対1トークでは既定値を返す' do
      event = line_message_event(source: line_user_source)

      expect(described_class.count_members(event)).to eq(described_class::DEFAULT_MEMBER_COUNT)
    end

    it '問い合わせに失敗した場合は既定値へ落とす' do
      allow(client).to receive(:get_group_member_count_with_http_info).and_return([nil, 404, {}])
      allow(Rails.logger).to receive(:warn)

      expect(described_class.count_members(line_message_event)).to eq(described_class::DEFAULT_MEMBER_COUNT)
      expect(Rails.logger).to have_received(:warn).with(/メンバー数を取得できませんでした/)
    end

    it '呼び出しの結果を記録する' do
      allow(client).to receive(:get_group_member_count_with_http_info)
        .and_return([Line::Bot::V2::MessagingApi::GroupMemberCountResponse.new(count: 5), 200, {}])
      allow(PrometheusMetrics).to receive(:track_line_api_call)

      described_class.count_members(line_message_event)

      expect(PrometheusMetrics).to have_received(:track_line_api_call)
        .with('get_group_member_count', 200, kind_of(Float))
    end
  end

  describe '.action_by_event_type' do
    it '人数が足りていればグループを記録する' do
      allow(described_class).to receive(:message_events)

      expect { described_class.action_by_event_type(line_message_event, 'GROUP123', 5) }
        .to change(LineGroup, :count).by(1)
    end

    it 'メッセージイベントを message_events へ渡す' do
      event = line_message_event
      allow(described_class).to receive(:message_events)

      described_class.action_by_event_type(event, 'GROUP123', 5)

      expect(described_class).to have_received(:message_events).with(event, 'GROUP123', 5)
    end

    it '参加イベントを join_events へ渡す' do
      event = line_join_event
      allow(described_class).to receive(:join_events)

      described_class.action_by_event_type(event, 'GROUP123', 5)

      expect(described_class).to have_received(:join_events).with(event, 'GROUP123')
    end

    it 'メンバー参加イベントを join_events へ渡す' do
      event = line_member_joined_event
      allow(described_class).to receive(:join_events)

      described_class.action_by_event_type(event, 'GROUP123', 5)

      expect(described_class).to have_received(:join_events).with(event, 'GROUP123')
    end

    it '退出イベントを leave_events へ渡す' do
      allow(described_class).to receive(:leave_events)

      described_class.action_by_event_type(line_leave_event, 'GROUP123', 1)

      expect(described_class).to have_received(:leave_events).with('GROUP123', 1)
    end

    it 'メンバー退出イベントを leave_events へ渡す' do
      allow(described_class).to receive(:leave_events)

      described_class.action_by_event_type(line_member_left_event, 'GROUP123', 1)

      expect(described_class).to have_received(:leave_events).with('GROUP123', 1)
    end

    it '扱わない種類のイベントでは何もしない' do
      expect { described_class.action_by_event_type(line_follow_event, 'GROUP123', 5) }
        .not_to raise_error
    end
  end

  describe '.join_events' do
    it 'Bot が加わったときは挨拶を予約する' do
      expect { described_class.join_events(line_join_event, 'GROUP123') }
        .to have_enqueued_job(LineWelcomeMessageJob).with('GROUP123', described_class::JOIN_MESSAGE)
    end

    it 'メンバーが加わったときは自己紹介を予約する' do
      expect { described_class.join_events(line_member_joined_event, 'GROUP123') }
        .to have_enqueued_job(LineWelcomeMessageJob).with('GROUP123', described_class::MEMBER_JOINED_MESSAGE)
    end
  end

  describe '.leave_events' do
    let!(:line_group) { create(:line_group, line_group_id: 'GROUP123') }

    it '誰もいなくなったグループの記録を消す' do
      expect { described_class.leave_events('GROUP123', 1) }.to change(LineGroup, :count).by(-1)
    end

    it 'まだメンバーが残っている場合は記録を残す' do
      expect { described_class.leave_events('GROUP123', 5) }.not_to change(LineGroup, :count)
    end

    it '記録が無いグループでも失敗しない' do
      expect { described_class.leave_events('UNKNOWN', 1) }.not_to raise_error
      expect(line_group.reload).to be_present
    end
  end
end
