# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestCorrelation do
  let(:downstream_response) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
  let(:app) { ->(_env) { downstream_response } }
  let(:middleware) { described_class.new(app) }

  after { RequestStore.clear! }

  context 'when the X-Request-ID header is present' do
    it 'uses the header value as the request_id' do
      captured = {}
      app = lambda do |_env|
        captured[:request_id] = RequestStore.store[:request_id]
        captured[:correlation_id] = RequestStore.store[:correlation_id]
        downstream_response
      end

      described_class.new(app).call('HTTP_X_REQUEST_ID' => 'abc-123')

      expect(captured[:request_id]).to eq('abc-123')
      expect(captured[:correlation_id]).to eq('abc-123')
    end
  end

  context 'when the X-Request-ID header is absent' do
    it 'generates a UUID as the request_id' do
      allow(SecureRandom).to receive(:uuid).and_return('generated-uuid')
      captured = {}
      app = lambda do |_env|
        captured[:request_id] = RequestStore.store[:request_id]
        downstream_response
      end

      described_class.new(app).call({})

      expect(captured[:request_id]).to eq('generated-uuid')
    end
  end

  it 'returns the downstream response' do
    expect(middleware.call({})).to eq(downstream_response)
  end

  it 'clears RequestStore after the request to prevent leakage' do
    middleware.call('HTTP_X_REQUEST_ID' => 'abc-123')

    expect(RequestStore.store[:request_id]).to be_nil
  end

  it 'clears RequestStore even when the downstream app raises' do
    failing_app = ->(_env) { raise 'boom' }

    expect { described_class.new(failing_app).call({}) }.to raise_error('boom')
    expect(RequestStore.store[:request_id]).to be_nil
  end
end
