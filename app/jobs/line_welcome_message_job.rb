class LineWelcomeMessageJob < ApplicationJob
  queue_as :default

  def perform(group_id, text)
    CatLineBot.push_message(group_id, text)
    PrometheusMetrics.track_message_send('success')
  rescue StandardError => e
    Rails.logger.error("挨拶の送信に失敗しました(#{group_id}): #{e.message}")
    PrometheusMetrics.track_message_send('error')
    raise
  end
end
