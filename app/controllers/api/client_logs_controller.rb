class Api::ClientLogsController < ApplicationController
  skip_before_action :verify_authenticity_token

  MAX_LOGS_PER_REQUEST = 100

  def create
    logs_params = params.permit(logs: [:level, :message, :url, :trace_id, { context: {} }])
    logs = logs_params[:logs]

    return render_error('No logs provided') if logs.blank?
    return render_error("Maximum #{MAX_LOGS_PER_REQUEST} logs per request") if logs.size > MAX_LOGS_PER_REQUEST

    log_entries = build_log_entries(logs)
    invalid_entries = log_entries.reject { |entry| valid_log_entry?(entry) }

    return render_invalid_entries(invalid_entries.size) if invalid_entries.any?

    ClientLog.insert_all(log_entries) # rubocop:disable Rails/SkipsModelValidations

    render json: { success: true, count: log_entries.size }, status: :created
  rescue StandardError => e
    Rails.logger.error("ClientLogsController error: #{e.message}")
    render json: { error: 'Internal server error' }, status: :internal_server_error
  end

  private

  def build_log_entries(logs)
    logs.map do |log|
      {
        level: log[:level],
        message: log[:message],
        context: log[:context],
        url: log[:url],
        trace_id: log[:trace_id],
        user_agent: request.user_agent,
        created_at: Time.current
      }
    end
  end

  def valid_log_entry?(entry)
    return false if entry[:level].blank?
    return false if entry[:message].blank?
    return false unless ClientLog::VALID_LEVELS.include?(entry[:level])

    true
  end

  def render_error(message)
    render json: { error: message }, status: :unprocessable_entity
  end

  def render_invalid_entries(count)
    render json: { error: 'Invalid log entries', details: count }, status: :unprocessable_entity
  end
end
