# frozen_string_literal: true

require 'rails_helper'

# callback のパスは暗号化された credentials から組み立てるため(マスターキーが無いと引けない)、
# リクエストスペックではなく、経路を引き直したコントローラースペックとして書いています。
RSpec.describe Operator::WebhooksController, type: :controller do
  let(:body) { '{"events":[]}' }

  # `routes.draw` はアプリ全体の経路を書き換えるため、他のテストへ影響しないよう元へ戻します。
  after { Rails.application.reload_routes! }

  before do
    routes.draw { post 'callback' => 'operator/webhooks#callback' }
    stub_line_credentials
    allow(PrometheusMetrics).to receive(:track_webhook_request)
  end

  def signature_for(request_body)
    Base64.strict_encode64(
      OpenSSL::HMAC.digest(OpenSSL::Digest.new('SHA256'), 'test_channel_secret', request_body)
    )
  end

  context 'when 署名が無いとき' do
    it 'bad_request を返す' do
      post :callback, body: body

      expect(response).to have_http_status(:bad_request)
      expect(PrometheusMetrics).to have_received(:track_webhook_request).with('invalid_signature')
    end
  end

  context 'when 署名が正しくないとき' do
    it 'bad_request を返す' do
      request.headers['X-Line-Signature'] = 'invalid-signature'

      post :callback, body: body

      expect(response).to have_http_status(:bad_request)
      expect(PrometheusMetrics).to have_received(:track_webhook_request).with('invalid_signature')
    end
  end

  context 'when 署名が正しいとき' do
    before { request.headers['X-Line-Signature'] = signature_for(body) }

    it 'イベントを処理して ok を返す' do
      allow(CatLineBot).to receive(:line_bot_action)

      post :callback, body: body

      expect(response).to have_http_status(:ok)
      expect(CatLineBot).to have_received(:line_bot_action).with([])
      expect(PrometheusMetrics).to have_received(:track_webhook_request).with('success')
    end

    it '処理に失敗した場合は service_unavailable を返し、機密を伏せて記録する' do
      allow(CatLineBot).to receive(:line_bot_action).and_raise(StandardError, 'channel_secret: super-secret-token')
      allow(Rails.logger).to receive(:error)

      post :callback, body: body

      expect(response).to have_http_status(:service_unavailable)
      expect(PrometheusMetrics).to have_received(:track_webhook_request).with('error')
      expect(Rails.logger).to have_received(:error).with(/\[REDACTED\]/)
    end
  end
end
