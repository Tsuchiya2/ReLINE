# frozen_string_literal: true

# LINE の Webhook イベントを組み立てるためのヘルパーです。
module LineTestHelpers
  # イベントの発生時刻(ミリ秒)
  EVENT_TIMESTAMP = 1_700_000_000_000

  # LINE のチャネル情報を差し替えます
  def stub_line_credentials
    allow(Rails.application).to receive(:credentials).and_return(
      double(channel_secret: 'test_channel_secret',
             channel_token: 'test_channel_token',
             callback_route: 'callback',
             operator: { email: 'test@example.com' })
    )
    CatLineBot.reset!
  end

  def line_group_source(group_id = 'GROUP123')
    Line::Bot::V2::Webhook::GroupSource.new(group_id: group_id)
  end

  def line_room_source(room_id = 'ROOM123')
    Line::Bot::V2::Webhook::RoomSource.new(room_id: room_id)
  end

  def line_user_source(user_id = 'USER123')
    Line::Bot::V2::Webhook::UserSource.new(user_id: user_id)
  end

  def line_text_message(text = 'Hello')
    Line::Bot::V2::Webhook::TextMessageContent.new(id: 'MESSAGE_ID', text: text, quote_token: 'QUOTE_TOKEN')
  end

  def line_sticker_message
    Line::Bot::V2::Webhook::StickerMessageContent.new(
      id: 'MESSAGE_ID', package_id: '1', sticker_id: '1',
      sticker_resource_type: 'STATIC', quote_token: 'QUOTE_TOKEN'
    )
  end

  def line_image_message
    Line::Bot::V2::Webhook::ImageMessageContent.new(
      id: 'MESSAGE_ID', quote_token: 'QUOTE_TOKEN',
      content_provider: Line::Bot::V2::Webhook::ContentProvider.new(type: 'line')
    )
  end

  def line_message_event(source: line_group_source, message: line_text_message, reply_token: 'REPLY_TOKEN')
    Line::Bot::V2::Webhook::MessageEvent.new(
      **event_attributes, source: source, reply_token: reply_token, message: message
    )
  end

  def line_join_event(source: line_group_source)
    Line::Bot::V2::Webhook::JoinEvent.new(**event_attributes, source: source, reply_token: 'REPLY_TOKEN')
  end

  def line_member_joined_event(source: line_group_source)
    Line::Bot::V2::Webhook::MemberJoinedEvent.new(
      source: source,
      reply_token: 'REPLY_TOKEN',
      joined: Line::Bot::V2::Webhook::JoinedMembers.new(members: [line_user_source]),
      **event_attributes
    )
  end

  def line_leave_event(source: line_group_source)
    Line::Bot::V2::Webhook::LeaveEvent.new(**event_attributes, source: source)
  end

  def line_member_left_event(source: line_group_source)
    Line::Bot::V2::Webhook::MemberLeftEvent.new(
      source: source,
      left: Line::Bot::V2::Webhook::LeftMembers.new(members: [line_user_source]),
      **event_attributes
    )
  end

  def line_follow_event(source: line_user_source)
    Line::Bot::V2::Webhook::FollowEvent.new(
      source: source,
      reply_token: 'REPLY_TOKEN',
      follow: Line::Bot::V2::Webhook::FollowDetail.new(is_unblocked: false),
      **event_attributes
    )
  end

  private

  def event_attributes
    {
      timestamp: EVENT_TIMESTAMP,
      mode: 'active',
      webhook_event_id: 'WEBHOOK_EVENT_ID',
      delivery_context: Line::Bot::V2::Webhook::DeliveryContext.new(is_redelivery: false)
    }
  end
end

RSpec.configure do |config|
  config.include LineTestHelpers

  # メモ化したクライアントがテストを跨がないようにします
  config.before { CatLineBot.reset! }
end
