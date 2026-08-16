class MetricsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_monitor!, if: -> { Rails.env.production? }

  def index
    PrometheusMetrics.update_group_count(LineGroup.count)

    render plain: Prometheus::Client::Formats::Text.marshal(Prometheus::Client.registry),
           content_type: 'text/plain; version=0.0.4'
  end

  private

  def authenticate_monitor!
    username = ENV['MONITOR_USERNAME']
    password = ENV['MONITOR_PASSWORD']
    return head :forbidden if username.blank? || password.blank?

    authenticate_or_request_with_http_basic('Monitoring') do |user, pass|
      ActiveSupport::SecurityUtils.secure_compare(user, username) &&
        ActiveSupport::SecurityUtils.secure_compare(pass, password)
    end
  end
end
