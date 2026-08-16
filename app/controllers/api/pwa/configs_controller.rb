class Api::Pwa::ConfigsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    render json: config_data, status: :ok
  end

  private

  def config_data
    {
      version: pwa_config[:version] || 'v1',
      cache: build_cache_config,
      network: pwa_config[:network] || default_network_config,
      manifest: pwa_config[:manifest] || {},
      features: pwa_config[:features] || default_features,
      observability: pwa_config[:observability] || {}
    }
  end

  def build_cache_config
    cache_config = pwa_config[:cache] || {}
    cache_config.transform_values do |settings|
      {
        strategy: settings[:strategy],
        patterns: Array(settings[:patterns]),
        max_age: settings[:max_age],
        timeout: settings[:timeout]
      }.compact
    end
  end

  def pwa_config
    @pwa_config ||= Rails.application.config_for(:pwa_config)
  end

  def default_network_config
    { timeout: 3000, retries: 1 }
  end

  def default_features
    { install_prompt: true, push_notifications: false, background_sync: false }
  end
end
