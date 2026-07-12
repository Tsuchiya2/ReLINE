# frozen_string_literal: true

require 'rails_helper'

# Covers the defensive nil-value guard in valid_metric_entry?, which is
# otherwise unreachable because build_metric_entries coerces values with `to_d`.
RSpec.describe Api::MetricsController, type: :controller do
  describe 'POST #create' do
    it 'rejects an entry whose built value is nil' do
      allow(controller).to receive(:build_metric_entries).and_return(
        [{ name: 'broken', value: nil, unit: nil, tags: nil, trace_id: nil, created_at: Time.current }]
      )

      post :create, params: { metrics: [{ name: 'broken', value: 1 }] }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to eq('Invalid metric entries')
    end
  end
end
