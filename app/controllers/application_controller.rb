class ApplicationController < ActionController::Base
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :operator_not_authorized
  add_flash_types :success, :info, :warning, :danger

  def operator_not_authorized
    render file: Rails.root.join('public/403.html'), status: :forbidden, layout: false, content_type: 'text/html'
  end

  private

  def append_info_to_payload(payload)
    super
    payload[:request_id] = request.request_id
  end
end
