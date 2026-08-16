class ManifestsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    render json: manifest_data, content_type: 'application/manifest+json'
  end

  private

  def manifest_data
    {
      name: I18n.t('pwa.name'),
      short_name: I18n.t('pwa.short_name'),
      description: I18n.t('pwa.description'),
      start_url: '/?utm_source=pwa&utm_medium=homescreen',
      display: pwa_config.dig(:manifest, :display) || 'standalone',
      orientation: pwa_config.dig(:manifest, :orientation) || 'portrait',
      theme_color: pwa_config.dig(:manifest, :theme_color) || '#0d6efd',
      background_color: pwa_config.dig(:manifest, :background_color) || '#ffffff',
      lang: I18n.locale.to_s,
      dir: 'ltr',
      icons: icon_definitions,
      categories: pwa_config.dig(:manifest, :categories) || %w[productivity social]
    }
  end

  def icon_definitions
    [
      {
        src: '/pwa/icon-192.png',
        sizes: '192x192',
        type: 'image/png',
        purpose: 'any'
      },
      {
        src: '/pwa/icon-512.png',
        sizes: '512x512',
        type: 'image/png',
        purpose: 'any'
      },
      {
        src: '/pwa/icon-maskable-512.png',
        sizes: '512x512',
        type: 'image/png',
        purpose: 'maskable'
      }
    ]
  end

  def pwa_config
    @pwa_config ||= Rails.application.config_for(:pwa_config)
  end
end
