module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_current_operator
    helper_method :current_operator, :operator_signed_in?
  end

  def authenticate_operator(email, password)
    started_at = Time.current
    operator, reason = verify_credentials(email, password)

    PrometheusMetrics.track_authentication(reason.nil? ? :success : :failed,
                                           reason: reason, duration: Time.current - started_at)
    log_authentication(operator, reason)
    operator
  end

  def login(operator)
    reset_session
    session[:operator_id] = operator.id
    @current_operator = operator
  end

  def logout
    reset_session
    @current_operator = nil
  end

  attr_reader :current_operator

  def operator_signed_in?
    current_operator.present?
  end

  def require_authentication
    return if operator_signed_in?

    not_authenticated
  end

  def not_authenticated
    redirect_to operator_cat_in_path,
                alert: I18n.t('authentication.errors.session_expired',
                              default: 'ログインが必要です')
  end

  private

  def verify_credentials(email, password)
    operator = Operator.find_by(email: email)
    return [nil, :user_not_found] if operator.blank?

    if operator.locked?
      operator.mail_notice(request.remote_ip)
      return [nil, :account_locked]
    end

    unless operator.authenticate(password)
      operator.increment_failed_logins!
      return [nil, :invalid_credentials]
    end

    operator.reset_failed_logins!
    [operator, nil]
  end

  def set_current_operator
    return if session[:operator_id].blank?

    @current_operator ||= Operator.find_by(id: session[:operator_id])
    reset_session if @current_operator.nil?
    @current_operator
  end

  def log_authentication(operator, reason)
    Rails.logger.info(
      event: 'authentication_attempt',
      result: reason.nil? ? :success : :failed,
      reason: reason,
      operator_id: operator&.id,
      ip: request.remote_ip,
      request_id: request.request_id,
      timestamp: Time.current.iso8601
    )
  end
end
