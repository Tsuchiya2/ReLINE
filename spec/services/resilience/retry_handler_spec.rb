# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Resilience::RetryHandler do
  describe '#call' do
    it 'returns the block result when it succeeds on the first attempt' do
      handler = described_class.new
      expect(handler.call { 42 }).to eq(42)
    end

    it 'retries a retryable error and returns the eventual result' do
      handler = described_class.new(max_attempts: 3, backoff_factor: 2)
      allow(handler).to receive(:sleep) # avoid real backoff delay
      attempts = 0

      result = handler.call do
        attempts += 1
        raise Net::OpenTimeout if attempts < 2

        'recovered'
      end

      expect(result).to eq('recovered')
      expect(attempts).to eq(2)
    end

    it 're-raises the error after exceeding max attempts' do
      handler = described_class.new(max_attempts: 2, backoff_factor: 2)
      allow(handler).to receive(:sleep)

      expect { handler.call { raise Net::ReadTimeout } }.to raise_error(Net::ReadTimeout)
    end

    it 'does not retry a non-retryable error' do
      handler = described_class.new(max_attempts: 3)

      expect { handler.call { raise ArgumentError, 'nope' } }.to raise_error(ArgumentError, 'nope')
    end

    it 'retries an error that carries a 500 response' do
      error_class = Class.new(StandardError) do
        def response
          Struct.new(:code).new('500')
        end
      end
      handler = described_class.new(max_attempts: 2, backoff_factor: 2)
      allow(handler).to receive(:sleep)
      attempts = 0

      result = handler.call do
        attempts += 1
        raise error_class if attempts < 2

        'ok'
      end

      expect(result).to eq('ok')
    end

    it 'does not retry an error whose response is not a 500' do
      error_class = Class.new(StandardError) do
        def response
          Struct.new(:code).new('404')
        end
      end
      handler = described_class.new(max_attempts: 3)

      expect { handler.call { raise error_class } }.to raise_error(error_class)
    end

    it 'does not retry an error whose response is nil' do
      error_class = Class.new(StandardError) do
        def response
          nil
        end
      end
      handler = described_class.new(max_attempts: 3)

      expect { handler.call { raise error_class } }.to raise_error(error_class)
    end
  end
end
