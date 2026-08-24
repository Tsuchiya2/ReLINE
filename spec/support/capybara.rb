# Only load for system tests
return unless RSpec.configuration.files_to_run.any? { |f| f.include?('spec/system') }

require 'selenium-webdriver'

Capybara.default_max_wait_time = 5
Capybara.server = :puma, { Silent: true }

# Prefer system Chromium/chromedriver when installed (Docker on arm64,
# where Selenium Manager cannot download Chrome for Testing).
# On CI (GitHub Actions), these paths are absent and Selenium Manager
# resolves Chrome/chromedriver automatically as before.
SYSTEM_CHROMIUM_BIN = ['/usr/bin/chromium', '/usr/bin/chromium-browser'].find { |path| File.exist?(path) }
SYSTEM_CHROMEDRIVER = ('/usr/bin/chromedriver' if File.exist?('/usr/bin/chromedriver')).freeze
Selenium::WebDriver::Chrome::Service.driver_path = SYSTEM_CHROMEDRIVER if SYSTEM_CHROMEDRIVER

# Configure Chrome options for CI environment
Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1920,1080')
  options.add_argument('--disable-blink-features=AutomationControlled')
  options.binary = SYSTEM_CHROMIUM_BIN if SYSTEM_CHROMIUM_BIN

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Configure Chrome driver with PWA/Service Worker support
Capybara.register_driver :headless_chrome_pwa do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1920,1080')
  options.add_argument('--disable-blink-features=AutomationControlled')

  # Enable service worker support
  options.add_argument('--enable-features=NetworkService,NetworkServiceInProcess')

  # Enable logging preferences for debugging
  options.logging_prefs = { browser: 'ALL' }
  options.binary = SYSTEM_CHROMIUM_BIN if SYSTEM_CHROMIUM_BIN

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: options
  )
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    # Use custom headless Chrome driver
    driven_by :headless_chrome
  end

  config.after(:each, type: :system) do
    # Accept any open alerts before resetting (only for Selenium driver)
    if page.driver.is_a?(Capybara::Selenium::Driver)
      begin
        page.driver.browser.switch_to.alert.accept
      rescue Selenium::WebDriver::Error::NoSuchAlertError
        # No alert present, continue
      end
    end
    # Clear sessions and reset driver after each test
    Capybara.reset_sessions!
    Capybara.use_default_driver
    # Wait a moment to ensure cleanup completes
    sleep 0.1
  end
end

# Turbo DriveがDOMを差し替えている最中にCapybaraが問い合わせると、chromedriverが
# `unknown error: unhandled inspector error: {"code":-32000,"message":"Node with
# given id does not belong to the document"}` を返すことがある。差し替えが終われば
# 解消する一過性のエラーだが、Capybaraの再試行対象（invalid_element_errors）に
# UnknownErrorは含まれないため、待機せずそのまま失敗してしまう。
# StaleElementReferenceErrorなどと同じく再試行の対象に加えて、待ち時間内であれば
# 差し替え完了後に成功できるようにする。なお待ち時間を過ぎれば元の例外がそのまま
# 送出されるので、本物のエラーを握り潰すことはない。
module RetryTransientDocumentNodeError
  TRANSIENT_MESSAGE = 'does not belong to the document'.freeze

  protected

  def catch_error?(error, errors = nil)
    return true if transient_document_node_error?(error)

    super
  end

  private

  def transient_document_node_error?(error)
    error.is_a?(Selenium::WebDriver::Error::UnknownError) &&
      error.message.to_s.include?(TRANSIENT_MESSAGE)
  end
end

Capybara::Node::Base.prepend(RetryTransientDocumentNodeError)
