class LineReminderJob < ApplicationJob
  queue_as :default

  def perform(group_id, texts)
    texts.each do |text|
      CatLineBot.push_message(group_id, text)
      PrometheusMetrics.track_message_send('success')
    end
  rescue StandardError => e
    Rails.logger.error("働きかけの送信に失敗しました(#{group_id}): #{e.message}")
    PrometheusMetrics.track_message_send('error')
    raise
  end
end
