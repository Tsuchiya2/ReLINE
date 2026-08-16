class Api::MetricsController < ApplicationController
  skip_before_action :verify_authenticity_token

  MAX_METRICS_PER_REQUEST = 100

  def create
    metrics_params = params.permit(metrics: [:name, :value, :unit, :trace_id, { tags: {} }])
    metrics = metrics_params[:metrics]

    return render_validation_error('No metrics provided') if metrics.blank?
    return render_validation_error("Maximum #{MAX_METRICS_PER_REQUEST} metrics per request") if metrics.size > MAX_METRICS_PER_REQUEST

    metric_entries = build_metric_entries(metrics)

    invalid_entries = metric_entries.reject { |entry| valid_metric_entry?(entry) }
    return render_validation_error('Invalid metric entries', invalid_entries.size) if invalid_entries.any?

    Metric.insert_all(metric_entries) # rubocop:disable Rails/SkipsModelValidations

    render json: { success: true, count: metric_entries.size }, status: :created
  rescue StandardError => e
    Rails.logger.error("MetricsController error: #{e.message}")
    render json: { error: 'Internal server error' }, status: :internal_server_error
  end

  private

  def build_metric_entries(metrics)
    metrics.map do |metric|
      {
        name: metric[:name],
        value: metric[:value].to_d,
        unit: metric[:unit],
        tags: metric[:tags],
        trace_id: metric[:trace_id],
        created_at: Time.current
      }
    end
  end

  def valid_metric_entry?(entry)
    return false if entry[:name].blank?
    return false if entry[:value].nil?

    true
  end

  def render_validation_error(message, details = nil)
    error_payload = { error: message }
    error_payload[:details] = details if details
    render json: error_payload, status: :unprocessable_entity
  end
end
