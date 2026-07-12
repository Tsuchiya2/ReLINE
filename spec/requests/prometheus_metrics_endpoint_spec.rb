# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GET /metrics', type: :request do
  def basic_auth(user, pass)
    { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(user, pass) }
  end

  context 'in a non-production environment' do
    it 'exposes metrics without authentication' do
      create(:line_group)
      get '/metrics'

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('text/plain')
      expect(response.body).to include('line_groups_total')
    end
  end

  context 'in production' do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
    end

    context 'when monitoring credentials are not configured' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('MONITOR_USERNAME').and_return(nil)
        allow(ENV).to receive(:[]).with('MONITOR_PASSWORD').and_return(nil)
      end

      it 'returns forbidden' do
        get '/metrics'
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when monitoring credentials are configured' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('MONITOR_USERNAME').and_return('monitor')
        allow(ENV).to receive(:[]).with('MONITOR_PASSWORD').and_return('s3cret')
      end

      it 'requires HTTP basic authentication' do
        get '/metrics'
        expect(response).to have_http_status(:unauthorized)
      end

      it 'grants access with the correct credentials' do
        get '/metrics', headers: basic_auth('monitor', 's3cret')
        expect(response).to have_http_status(:ok)
      end

      it 'rejects an incorrect password' do
        get '/metrics', headers: basic_auth('monitor', 'wrong')
        expect(response).to have_http_status(:unauthorized)
      end

      it 'rejects an incorrect username' do
        get '/metrics', headers: basic_auth('intruder', 's3cret')
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
