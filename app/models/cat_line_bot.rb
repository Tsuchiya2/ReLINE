class CatLineBot
  extend LineMessaging
  extend MessageEvent

  DEFAULT_MEMBER_COUNT = 2

  MEMBER_COUNT_TTL = 5.minutes

  JOIN_MESSAGE = '加えてくれてありがとうニャ🌟！！最後のLINEから3週間〜2ヶ月後にwake upのLINEするニャ！！' \
                 '（反応が無いとすぐかも知れニャンよ⏰）末永くよろしくニャ🐱🐾'.freeze

  MEMBER_JOINED_MESSAGE = '初めまして🌟ReLINE(https://www.cat-reline.com/)の"猫さん"っていうニャ🐱よろしくニャ🐾！！'.freeze

  class << self
    def line_bot_action(events)
      events.each do |event|
        parse_event(event)
      rescue StandardError => e
        report_error(e, event)
      end
    end

    def parse_event(event)
      started_at = Time.current
      group_id = current_group_id(event)

      if group_id.blank?
        one_on_one(event)
      else
        action_by_event_type(event, group_id, count_members(event))
      end

      PrometheusMetrics.track_event(event, 'success')
      PrometheusMetrics.track_event_duration(event, Time.current - started_at)
    end

    def current_group_id(event)
      case event.source
      when Line::Bot::V2::Webhook::GroupSource then event.source.group_id
      when Line::Bot::V2::Webhook::RoomSource  then event.source.room_id
      end
    end

    def count_members(event)
      case event.source
      when Line::Bot::V2::Webhook::GroupSource
        group_id = event.source.group_id
        member_count("line:group:#{group_id}") { group_member_count(group_id) }
      when Line::Bot::V2::Webhook::RoomSource
        room_id = event.source.room_id
        member_count("line:room:#{room_id}") { room_member_count(room_id) }
      else
        DEFAULT_MEMBER_COUNT
      end
    end

    def action_by_event_type(event, group_id, member_count)
      LineGroup.find_or_create_from_line!(group_id, member_count)

      case event
      when Line::Bot::V2::Webhook::MessageEvent
        message_events(event, group_id, member_count)
      when Line::Bot::V2::Webhook::JoinEvent, Line::Bot::V2::Webhook::MemberJoinedEvent
        join_events(event, group_id)
      when Line::Bot::V2::Webhook::LeaveEvent, Line::Bot::V2::Webhook::MemberLeftEvent
        leave_events(group_id, member_count)
      end
    end

    def join_events(event, group_id)
      text = event.is_a?(Line::Bot::V2::Webhook::JoinEvent) ? JOIN_MESSAGE : MEMBER_JOINED_MESSAGE
      LineWelcomeMessageJob.perform_later(group_id, text)
    end

    def leave_events(group_id, member_count)
      return if member_count >= LineGroup::MINIMUM_MEMBER_COUNT

      LineGroup.find_by(line_group_id: group_id)&.destroy!
    end

    private

    def member_count(cache_key, &block)
      Rails.cache.fetch(cache_key, expires_in: MEMBER_COUNT_TTL, &block)
    rescue StandardError => e
      Rails.logger.warn("メンバー数を取得できませんでした: #{e.message}")
      DEFAULT_MEMBER_COUNT
    end

    def report_error(exception, event)
      error_message = ErrorSanitizer.format(exception, 'Callback')
      Rails.logger.error(error_message)
      LineMailer.error_email(current_group_id(event), error_message).deliver_later
      PrometheusMetrics.track_event(event, 'error')
    end
  end
end
