# frozen_string_literal: true

require 'rails_helper'

# CatLineBot へ extend して使うモジュールのため、CatLineBot 越しに確かめます。
RSpec.describe MessageEvent, type: :model do
  let(:bot) { CatLineBot }
  let(:client) { instance_double(Line::Bot::V2::MessagingApi::ApiClient) }

  before do
    stub_line_credentials
    allow(bot).to receive(:client).and_return(client)
  end

  describe '#message_events' do
    context 'when "おまじない"を受け取ったとき' do
      let(:removal_command) { described_class::REMOVAL_COMMAND }

      it 'グループから退出する' do
        allow(client).to receive(:leave_group_with_http_info).with(group_id: 'GROUP123').and_return([nil, 200, {}])

        bot.message_events(line_message_event(message: line_text_message(removal_command)), 'GROUP123', 5)

        expect(client).to have_received(:leave_group_with_http_info)
      end

      it 'トークルームから退出する' do
        allow(client).to receive(:leave_room_with_http_info).with(room_id: 'ROOM123').and_return([nil, 200, {}])
        event = line_message_event(source: line_room_source, message: line_text_message(removal_command))

        bot.message_events(event, 'ROOM123', 5)

        expect(client).to have_received(:leave_room_with_http_info)
      end

      it 'グループの記録は更新しない' do
        allow(client).to receive(:leave_group_with_http_info).and_return([nil, 200, {}])
        allow(bot).to receive(:update_line_group_record)

        bot.message_events(line_message_event(message: line_text_message(removal_command)), 'GROUP123', 5)

        expect(bot).not_to have_received(:update_line_group_record)
      end
    end

    it '通常のメッセージはグループの記録へ反映する' do
      allow(bot).to receive(:update_line_group_record)
      event = line_message_event

      bot.message_events(event, 'GROUP123', 5)

      expect(bot).to have_received(:update_line_group_record).with(event, 'GROUP123', 5)
    end
  end

  describe '#update_line_group_record' do
    let!(:line_group) { create(:line_group, line_group_id: 'GROUP123', post_count: 0) }

    it '発言を受けて次の働きかけ日を設定し直す' do
      bot.update_line_group_record(line_message_event, 'GROUP123', 5)

      expect(line_group.reload).to have_attributes(post_count: 1, member_count: 5, status: 'wait')
    end

    it 'メンバーが足りない場合は何もしない' do
      bot.update_line_group_record(line_message_event, 'GROUP123', 1)

      expect(line_group.reload.post_count).to eq(0)
    end

    it '記録が無いグループでは何もしない' do
      expect { bot.update_line_group_record(line_message_event, 'UNKNOWN', 5) }.not_to raise_error
      expect(line_group.reload.post_count).to eq(0)
    end

    it 'テキスト以外のメッセージでもグループの記録を更新する' do
      bot.update_line_group_record(line_message_event(message: line_sticker_message), 'GROUP123', 5)

      expect(line_group.reload.post_count).to eq(1)
    end

    described_class::SPAN_COMMANDS.each do |command, expected|
      it "合言葉「#{command}」で働きかけの間隔を変える" do
        allow(client).to receive(:push_message_with_http_info).and_return([nil, 200, {}])

        bot.update_line_group_record(line_message_event(message: line_text_message(command)), 'GROUP123', 5)

        expect(line_group.reload.set_span).to eq(expected.to_s.delete_suffix('!'))
      end
    end

    it '間隔を変えたことを伝える' do
      allow(client).to receive(:push_message_with_http_info).and_return([nil, 200, {}])
      command = described_class::SPAN_COMMANDS.keys.first

      bot.update_line_group_record(line_message_event(message: line_text_message(command)), 'GROUP123', 5)

      expect(client).to have_received(:push_message_with_http_info) do |args|
        expect(args[:push_message_request].messages.map(&:text)).to eq([described_class::SPAN_CHANGED_MESSAGE])
      end
    end

    it '間隔を変えたときは働きかけ日を動かさない' do
      allow(client).to receive(:push_message_with_http_info).and_return([nil, 200, {}])
      command = described_class::SPAN_COMMANDS.keys.first

      bot.update_line_group_record(line_message_event(message: line_text_message(command)), 'GROUP123', 5)

      expect(line_group.reload.post_count).to eq(0)
    end
  end

  describe '#one_on_one' do
    before { allow(client).to receive(:reply_message_with_http_info).and_return([nil, 200, {}]) }

    def replied_text
      text = nil
      expect(client).to have_received(:reply_message_with_http_info) do |args|
        text = args[:reply_message_request].messages.map(&:text).first
      end
      text
    end

    it 'テキストには使い方を案内する' do
      bot.one_on_one(line_message_event(source: line_user_source))

      expect(replied_text).to include(described_class::HOW_TO_USE)
    end

    it 'スタンプにはお礼としてコンテンツを送る' do
      create(:content, category: :free, body: 'お礼のことば')

      bot.one_on_one(line_message_event(source: line_user_source, message: line_sticker_message))

      expect(replied_text).to include('お礼のことば')
    end

    it 'コンテンツが未登録ならスタンプにも定型文を返す' do
      bot.one_on_one(line_message_event(source: line_user_source, message: line_sticker_message))

      expect(replied_text).to eq(described_class::UNKNOWN_MESSAGE)
    end

    it 'テキストでもスタンプでもないメッセージには定型文を返す' do
      bot.one_on_one(line_message_event(source: line_user_source, message: line_image_message))

      expect(replied_text).to eq(described_class::UNKNOWN_MESSAGE)
    end

    it 'メッセージ以外のイベントには応答しない' do
      bot.one_on_one(line_follow_event)

      expect(client).not_to have_received(:reply_message_with_http_info)
    end
  end
end
