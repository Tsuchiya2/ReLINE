class ApplicationJob < ActiveJob::Base
  retry_on Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED,
           wait: :polynomially_longer, attempts: 3

  discard_on ActiveJob::DeserializationError
end
