module LineMessaging
  def client
    @client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: Rails.application.credentials.channel_token
    )
  end

  def parser
    @parser ||= Line::Bot::V2::WebhookParser.new(
      channel_secret: Rails.application.credentials.channel_secret
    )
  end

  def reset!
    @client = nil
    @parser = nil
  end

  def parse_events(body, signature)
    parser.parse(body: body, signature: signature)
  end

  def push_message(target, text)
    call_api('push_message') do
      client.push_message_with_http_info(
        push_message_request: Line::Bot::V2::MessagingApi::PushMessageRequest.new(
          to: target, messages: [text_message(text)]
        )
      )
    end
  end

  def reply_message(reply_token, text)
    call_api('reply_message') do
      client.reply_message_with_http_info(
        reply_message_request: Line::Bot::V2::MessagingApi::ReplyMessageRequest.new(
          reply_token: reply_token, messages: [text_message(text)]
        )
      )
    end
  end

  def leave_group(group_id)
    call_api('leave_group') { client.leave_group_with_http_info(group_id: group_id) }
  end

  def leave_room(room_id)
    call_api('leave_room') { client.leave_room_with_http_info(room_id: room_id) }
  end

  def group_member_count(group_id)
    call_api('get_group_member_count') { client.get_group_member_count_with_http_info(group_id: group_id) }.count
  end

  def room_member_count(room_id)
    call_api('get_room_member_count') { client.get_room_member_count_with_http_info(room_id: room_id) }.count
  end

  private

  def call_api(name)
    started_at = Time.current
    body, status, = yield
    PrometheusMetrics.track_line_api_call(name, status, Time.current - started_at)

    raise "LINE API #{name} が失敗しました(status: #{status})" unless status == 200

    body
  end

  def text_message(text)
    Line::Bot::V2::MessagingApi::TextMessage.new(text: text)
  end
end
