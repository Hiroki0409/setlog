require "capybara"
require "selenium-webdriver"

Capybara.register_driver :setlog_chromium do |app|
  options = Selenium::WebDriver::Options.chrome(binary: "/usr/bin/chromium")
  options.add_argument("--headless")
  options.add_argument("--window-size=1280,960")
  # テスト用コンテナではプロセスが root で動く。
  options.add_argument("--no-sandbox") if Process.uid.zero?
  options.add_argument("--disable-dev-shm-usage")

  service = Selenium::WebDriver::Service.chrome
  service.executable_path = "/usr/bin/chromedriver"

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, service: service)
end

module SystemBrowserHelpers
  def sign_in_through_browser(email:, password:)
    visit new_user_session_path
    fill_in "メールアドレス", with: email
    fill_in "パスワード", with: password
    click_button "ログイン"
  end
end

RSpec.configure do |config|
  config.include SystemBrowserHelpers, type: :system

  config.before(type: :system) do
    driven_by :setlog_chromium
  end
end
