class Operator::WebhooksController < Operator::BaseController
  skip_before_action :require_authentication, only: %i[callback]
  protect_from_forgery except: :callback

  def callback
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    return invalid_signature if signature.blank?

    CatLineBot.line_bot_action(CatLineBot.parse_events(request.body.read, signature))

    PrometheusMetrics.track_webhook_request('success')
    head :ok
  rescue Line::Bot::V2::WebhookParser::InvalidSignatureError
    invalid_signature
  rescue StandardError => e
    Rails.logger.error(ErrorSanitizer.format(e, 'Webhook'))
    PrometheusMetrics.track_webhook_request('error')
    head :service_unavailable
  end

  private

  def invalid_signature
    PrometheusMetrics.track_webhook_request('invalid_signature')
    head :bad_request
  end
end
