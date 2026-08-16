# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.custom_options = lambda do |event|
    {
      # リクエストの追跡
      request_id: event.payload[:request_id],

      # LINE の Webhook イベント
      group_id: event.payload[:group_id],
      event_type: event.payload[:event_type],

      # 認証イベント
      user_id: event.payload[:user_id],
      user_email: event.payload[:user_email],
      result: event.payload[:result],
      reason: event.payload[:reason],

      # 実行環境
      rails_version: Rails.version,
      line_bot_api_version: Line::Bot::VERSION,
      timestamp: Time.current.iso8601
    }
  end
end
