# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HealthController, type: :controller do
  def json
    JSON.parse(response.body)
  end

  # Force the DB connectivity probe (`SELECT 1`) to fail while leaving every
  # other query working, so `database_connected?` exercises its rescue branch.
  def stub_database_down
    allow(ActiveRecord::Base.connection).to receive(:execute).and_call_original
    allow(ActiveRecord::Base.connection).to receive(:execute)
      .with('SELECT 1')
      .and_raise(ActiveRecord::StatementInvalid.new('database unavailable'))
  end

  describe 'GET #show' do
    it 'returns ok' do
      get :show

      expect(response).to have_http_status(:ok)
      expect(json['status']).to eq('ok')
      expect(json['timestamp']).to be_present
      expect(json).to have_key('version')
    end
  end

  describe 'GET #deep' do
    context 'when all dependencies are healthy' do
      before do
        allow(controller).to receive(:`).and_return('/dev/root 20G 10G 10G 50% /')
      end

      it 'returns ok with database and disk_space checks' do
        get :deep

        expect(response).to have_http_status(:ok)
        expect(json['status']).to eq('ok')
        expect(json['checks']['database']['status']).to eq('ok')
        expect(json['checks']['database']['response_time_ms']).to be_present
        expect(json['checks']['disk_space']['status']).to eq('ok')
      end
    end

    context 'when the database is unavailable' do
      before do
        stub_database_down
        allow(controller).to receive(:`).and_return('/dev/root 20G 10G 10G 50% /')
      end

      it 'returns service_unavailable and reports the database as failed' do
        get :deep

        expect(response).to have_http_status(:service_unavailable)
        expect(json['status']).to eq('degraded')
        expect(json['checks']['database']['status']).to eq('error')
      end
    end

    context 'when measuring the database response time raises' do
      before do
        # database_connected? returns true against the real (up) test DB, so only
        # measure_database_response_time is stubbed to trigger check_database's rescue.
        allow(controller).to receive(:measure_database_response_time).and_raise(StandardError.new('timeout'))
        allow(controller).to receive(:`).and_return('/dev/root 20G 10G 10G 50% /')
      end

      it 'rescues the error and reports it in the database check' do
        get :deep

        expect(response).to have_http_status(:service_unavailable)
        expect(json['checks']['database']['status']).to eq('error')
        expect(json['checks']['database']['message']).to eq('timeout')
      end
    end

    context 'when disk space is low' do
      before do
        allow(controller).to receive(:`).and_return('/dev/root 20G 19G 1G 95% /')
      end

      it 'reports the disk_space check as a warning' do
        get :deep

        expect(response).to have_http_status(:service_unavailable)
        expect(json['checks']['disk_space']['status']).to eq('warning')
        expect(json['checks']['disk_space']['usage_percent']).to eq(95)
      end
    end

    context 'when the disk space check raises' do
      before do
        allow(controller).to receive(:`).and_raise(StandardError.new('df failed'))
      end

      it 'rescues the error and reports it in the disk_space check' do
        get :deep

        expect(response).to have_http_status(:service_unavailable)
        expect(json['checks']['disk_space']['status']).to eq('error')
        expect(json['checks']['disk_space']['message']).to eq('df failed')
      end
    end
  end

  describe 'GET #ready' do
    context 'when the database is connected' do
      it 'returns ready' do
        get :ready

        expect(response).to have_http_status(:ok)
        expect(json['status']).to eq('ready')
      end
    end

    context 'when the database is not connected' do
      before { stub_database_down }

      it 'returns not_ready' do
        get :ready

        expect(response).to have_http_status(:service_unavailable)
        expect(json['status']).to eq('not_ready')
        expect(json['reason']).to eq('database_unavailable')
      end
    end
  end
end
