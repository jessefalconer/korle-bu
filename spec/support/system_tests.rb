# frozen_string_literal: true

# Browser specs (spec/system): the pages run in a headless Chrome so their
# JavaScript is tested for real.
#
# They use Google's chrome-headless-shell, the Chrome for Testing build with no
# browser UI. Full headless Chrome 158 sometimes stops delivering any clicks or
# keys to the page partway through a run (which tests depends on the order), and
# the shell doesn't. Point CHROME_HEADLESS_SHELL at its binary, or unpack it under
# ~/.cache/selenium/chrome-headless-shell/ (version matching chromedriver):
#   https://googlechromelabs.github.io/chrome-for-testing/
# Without it the specs fall back to regular headless Chrome.
module SystemTestHelpers
  PASSWORD = "1234567890" # the users factory's password

  def self.headless_shell
    path = ENV["CHROME_HEADLESS_SHELL"].presence ||
           Dir.glob(File.expand_path("~/.cache/selenium/chrome-headless-shell/**/chrome-headless-shell")).max
    path if path && File.executable?(path)
  end

  # Visits a page and waits until its JavaScript has finished starting up
  # (application.js marks <html data-js-ready>), so clicks never race it.
  def visit_page(path)
    visit path
    expect(page).to have_css("html[data-js-ready]", visible: :all)
  end

  def log_in_as(user)
    visit login_path
    # A clean slate for what pages keep in the browser (e.g. collapsed dashboard cards)
    page.execute_script("localStorage.clear(); sessionStorage.clear()")
    fill_in "email", with: user.email
    fill_in "password", with: PASSWORD
    find("[type=submit]").click
    expect(page).to have_no_current_path(login_path)
  end
end

# Capybara 3.40 (the latest) clears browser storage between tests with
# Storage.clearDataForOrigin for origin "*", which Chrome 158+ rejects as "not a
# valid URL". When that happens, just clear the cookies; log_in_as clears local
# and session storage.
module ChromeStorageResetFix
  def reset!
    super
  rescue Selenium::WebDriver::Error::InvalidArgumentError => e
    raise unless e.message.include?("is not a valid URL")

    execute_cdp("Network.clearBrowserCookies")
  end
end
Capybara::Selenium::Driver::ChromeDriver.prepend(ChromeStorageResetFix)

RSpec.configure do |config|
  config.include SystemTestHelpers, type: :system

  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [1280, 900] do |options|
      shell = SystemTestHelpers.headless_shell
      options.binary = shell if shell
    end
  end

  # The compiled stylesheet isn't in git. Pages need it (".hidden", the dropdown
  # and dialog styles), so build it once if a fresh checkout doesn't have it yet.
  config.before(:suite) do
    built = Rails.root.join("app/assets/builds/application.css")
    system("bin/rails dartsass:build", exception: true) unless built.exist?
  end
end
