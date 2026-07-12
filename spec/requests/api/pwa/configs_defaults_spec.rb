# frozen_string_literal: true

require 'rails_helper'

# Covers the default_network_config / default_features fallbacks, used only when
# the pwa_config file omits those keys.
RSpec.describe 'Api::Pwa::Configs defaults', type: :request do
  it 'falls back to default network and feature config when the config omits them' do
    allow(Rails.application).to receive(:config_for).and_call_original
    allow(Rails.application).to receive(:config_for).with(:pwa_config).and_return({})

    get '/api/pwa/config'

    json = JSON.parse(response.body)
    expect(json['network']).to eq('timeout' => 3000, 'retries' => 1)
    expect(json['features']).to eq(
      'install_prompt' => true, 'push_notifications' => false, 'background_sync' => false
    )
  end
end
