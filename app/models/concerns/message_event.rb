module MessageEvent
  HOW_TO_USE = 'https://www.cat-reline.com/'.freeze

  REMOVAL_COMMAND = 'Cat sleeping on our Memory.'.freeze

  SPAN_COMMANDS = {
    'Would you set to faster.' => :faster!,
    'Would you set to latter.' => :latter!,
    'Would you set to default.' => :random!
  }.freeze

  SPAN_CHANGED_MESSAGE = '了解ニャ！次の投稿から設定を適応するニャ🐾！！'.freeze

  UNKNOWN_MESSAGE = 'ごめんニャ😿分からないニャ。。。'.freeze

  def message_events(event, group_id, member_count)
    return cat_back_to_memory(event, group_id) if message_text(event) == REMOVAL_COMMAND

    update_line_group_record(event, group_id, member_count)
  end

  def cat_back_to_memory(event, group_id)
    if event.source.is_a?(Line::Bot::V2::Webhook::RoomSource)
      leave_room(group_id)
    else
      leave_group(group_id)
    end
  end

  def update_line_group_record(event, group_id, member_count)
    return if member_count < LineGroup::MINIMUM_MEMBER_COUNT

    line_group = LineGroup.find_by(line_group_id: group_id)
    return if line_group.blank?

    span = SPAN_COMMANDS[message_text(event)]
    return line_group.update_record(member_count) if span.nil?

    update_set_span(line_group, span)
  end

  def update_set_span(line_group, span)
    line_group.public_send(span)
    push_message(line_group.line_group_id, SPAN_CHANGED_MESSAGE)
  end

  def one_on_one(event)
    return unless event.is_a?(Line::Bot::V2::Webhook::MessageEvent)

    reply_message(event.reply_token, one_on_one_text(event))
  end

  private

  def message_text(event)
    event.message.text if event.message.is_a?(Line::Bot::V2::Webhook::TextMessageContent)
  end

  def one_on_one_text(event)
    case event.message
    when Line::Bot::V2::Webhook::TextMessageContent
      "【ReLINE】の使い方はこちらで確認してほしいにゃ！🐱🐾#{HOW_TO_USE}"
    when Line::Bot::V2::Webhook::StickerMessageContent
      thanks_for_sticker
    else
      UNKNOWN_MESSAGE
    end
  end

  def thanks_for_sticker
    body = Content.sample_body(:free)
    return UNKNOWN_MESSAGE if body.blank?

    "スタンプありがとうニャ！✨\nお礼にこちらをお送りするニャ🐾🐾\n#{body}"
  end
end
