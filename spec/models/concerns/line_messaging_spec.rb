# frozen_string_literal: true

require 'rails_helper'

# CatLineBot へ extend して使うモジュールのため、CatLineBot 越しに確かめます。
RSpec.describe LineMessaging, type: :model do
  let(:bot) { CatLineBot }
  let(:client) { instance_double(Line::Bot::V2::MessagingApi::ApiClient) }

  before { stub_line_credentials }

  describe '#client' do
    it 'チャネルアクセストークンを渡してクライアントを組み立てる' do
      expect(bot.client).to be_a(Line::Bot::V2::MessagingApi::ApiClient)
    end

    it '2 回目以降は同じクライアントを返す' do
      expect(bot.client).to equal(bot.client)
    end
  end

  describe '#parser' do
    it 'チャネルシークレットを渡してパーサーを組み立てる' do
      expect(bot.parser).to be_a(Line::Bot::V2::WebhookParser)
    end

    it '2 回目以降は同じパーサーを返す' do
      expect(bot.parser).to equal(bot.parser)
    end
  end

  describe '#reset!' do
    it '保持しているクライアントとパーサーを捨てる' do
      parser = bot.parser
      bot.reset!

      expect(bot.parser).not_to equal(parser)
    end
  end

  describe '#parse_events' do
    it '署名を渡してパーサーへ委ねる' do
      parser = instance_double(Line::Bot::V2::WebhookParser)
      allow(bot).to receive(:parser).and_return(parser)
      allow(parser).to receive(:parse).with(body: '{}', signature: 'signature').and_return([])

      expect(bot.parse_events('{}', 'signature')).to eq([])
    end
  end

  context 'when LINE API を呼び出すとき' do
    before { allow(bot).to receive(:client).and_return(client) }

    describe '#push_message' do
      it '宛先と本文を組み立てて送信する' do
        allow(client).to receive(:push_message_with_http_info).and_return([nil, 200, {}])

        bot.push_message('GROUP123', 'こんにちは')

        expect(client).to have_received(:push_message_with_http_info) do |args|
          request = args[:push_message_request]
          expect(request.to).to eq('GROUP123')
          expect(request.messages.map(&:text)).to eq(['こんにちは'])
        end
      end

      it '送信に失敗した場合は例外を投げる' do
        allow(client).to receive(:push_message_with_http_info).and_return([nil, 429, {}])

        expect { bot.push_message('GROUP123', 'こんにちは') }
          .to raise_error(/LINE API push_message が失敗しました\(status: 429\)/)
      end

      it '呼び出しの結果を記録する' do
        allow(client).to receive(:push_message_with_http_info).and_return([nil, 200, {}])
        allow(PrometheusMetrics).to receive(:track_line_api_call)

        bot.push_message('GROUP123', 'こんにちは')

        expect(PrometheusMetrics).to have_received(:track_line_api_call)
          .with('push_message', 200, kind_of(Float))
      end
    end

    describe '#reply_message' do
      it '応答トークンと本文を組み立てて返信する' do
        allow(client).to receive(:reply_message_with_http_info).and_return([nil, 200, {}])

        bot.reply_message('REPLY_TOKEN', 'ありがとう')

        expect(client).to have_received(:reply_message_with_http_info) do |args|
          request = args[:reply_message_request]
          expect(request.reply_token).to eq('REPLY_TOKEN')
          expect(request.messages.map(&:text)).to eq(['ありがとう'])
        end
      end
    end

    describe '#leave_group' do
      it 'グループから退出する' do
        allow(client).to receive(:leave_group_with_http_info).and_return([nil, 200, {}])

        bot.leave_group('GROUP123')

        expect(client).to have_received(:leave_group_with_http_info).with(group_id: 'GROUP123')
      end
    end

    describe '#leave_room' do
      it 'トークルームから退出する' do
        allow(client).to receive(:leave_room_with_http_info).and_return([nil, 200, {}])

        bot.leave_room('ROOM123')

        expect(client).to have_received(:leave_room_with_http_info).with(room_id: 'ROOM123')
      end
    end

    describe '#group_member_count' do
      it 'グループの人数を返す' do
        allow(client).to receive(:get_group_member_count_with_http_info)
          .with(group_id: 'GROUP123')
          .and_return([Line::Bot::V2::MessagingApi::GroupMemberCountResponse.new(count: 5), 200, {}])

        expect(bot.group_member_count('GROUP123')).to eq(5)
      end
    end

    describe '#room_member_count' do
      it 'トークルームの人数を返す' do
        allow(client).to receive(:get_room_member_count_with_http_info)
          .with(room_id: 'ROOM123')
          .and_return([Line::Bot::V2::MessagingApi::RoomMemberCountResponse.new(count: 3), 200, {}])

        expect(bot.room_member_count('ROOM123')).to eq(3)
      end
    end
  end
end
