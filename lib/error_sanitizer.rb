module ErrorSanitizer
  SENSITIVE_PATTERNS = [
    /channel_(?:id|secret|token)[=:]\s*\S+/i,
    /authorization[=:]\s*\S+/i,
    /bearer\s+\S+/i
  ].freeze

  MASK = '[REDACTED]'.freeze

  BACKTRACE_LINES = 5

  class << self
    def sanitize(message)
      SENSITIVE_PATTERNS.inject(message.to_s) { |text, pattern| text.gsub(pattern, MASK) }
    end

    def format(exception, context)
      <<~ERROR
        <#{context}>
        例外: #{exception.class}
        メッセージ: #{sanitize(exception.message)}
        バックトレース(先頭#{BACKTRACE_LINES}行):
        #{exception.backtrace&.first(BACKTRACE_LINES)&.join("\n")}
      ERROR
    end
  end
end
