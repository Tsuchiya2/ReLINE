# frozen_string_literal: true

require 'rails_helper'

# The callback route lives at a secret path derived from encrypted credentials
# (unavailable without the master key), so this is a controller spec with an
# explicitly drawn route rather than a request spec.
RSpec.describe Operator::WebhooksController, type: :controller do
  let(:validator) { instance_double(Webhooks::SignatureValidator) }
  let(:adapter) { instance_double(Line::SdkV2Adapter) }
  let(:processor) { instance_double(Line::EventProcessor) }
  let(:body) { '{"events":[]}' }

  # `routes.draw` mutates the global application route set, so restore the real
  # routes afterwards to avoid breaking other specs.
  after { Rails.application.reload_routes! }

  before do
    routes.draw { post 'callback' => 'operator/webhooks#callback' }
    allow(Webhooks::SignatureValidator).to receive(:new).and_return(validator)
    allow(Line::ClientProvider).to receive(:client).and_return(adapter)
    allow(Line::EventProcessor).to receive(:new).and_return(processor)
    allow(PrometheusMetrics).to receive(:track_webhook_request)
  end

  context 'when the signature header is missing' do
    it 'returns bad_request without validating' do
      post :callback, body: body

      expect(response).to have_http_status(:bad_request)
    end
  end

  context 'when the signature is invalid' do
    it 'returns bad_request' do
      allow(validator).to receive(:valid?).and_return(false)
      request.headers['X-Line-Signature'] = 'invalid-signature'

      post :callback, body: body

      expect(response).to have_http_status(:bad_request)
    end
  end

  context 'when the signature is valid' do
    before do
      allow(validator).to receive(:valid?).and_return(true)
      allow(adapter).to receive(:parse_events).with(body).and_return([])
      request.headers['X-Line-Signature'] = 'valid-signature'
    end

    it 'processes the events and returns ok' do
      allow(processor).to receive(:process)

      post :callback, body: body

      expect(response).to have_http_status(:ok)
      expect(processor).to have_received(:process).with([])
      expect(PrometheusMetrics).to have_received(:track_webhook_request).with('success')
    end

    it 'returns service_unavailable and tracks a timeout on Timeout::Error' do
      allow(processor).to receive(:process).and_raise(Timeout::Error)

      post :callback, body: body

      expect(response).to have_http_status(:service_unavailable)
      expect(PrometheusMetrics).to have_received(:track_webhook_request).with('timeout')
    end

    it 'returns service_unavailable and logs a sanitized error on StandardError' do
      allow(processor).to receive(:process).and_raise(StandardError.new('channel_secret: super-secret-token'))
      allow(Rails.logger).to receive(:error)

      post :callback, body: body

      expect(response).to have_http_status(:service_unavailable)
      expect(PrometheusMetrics).to have_received(:track_webhook_request).with('error')
      expect(Rails.logger).to have_received(:error).with(/Webhook processing failed: \[REDACTED\]/)
    end
  end
end
