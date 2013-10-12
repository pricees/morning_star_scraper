# Public: Scrape the financial statements and key ratios for SYMBOLS
#
# NOTE: Morningstar is a ghetto.
# They use a unique id for multiple elements, their html is whack, there is
# crazy javascript... its gotta be by design.
#
require 'rubygems'
require 'capybara'
require 'capybara/dsl'
require "selenium-webdriver"

Capybara.run_server = false
Capybara.app_host = 'http://financials.morningstar.com'

mimes = [
  "text/plain",
  "application/csv",
  "text/csv",
  "text/html",
  "text/comma-separated-values",
]

# Create a driver that automagically downloads
Capybara.register_driver :auto_dl do |app|
  profile = Selenium::WebDriver::Firefox::Profile.new
  profile["browser.helperApps.neverAsk.saveToDisk"] = mimes.join(", ")
  profile['browser.download.dir'] = "/tmp/webdriver-downloads"
  profile['browser.download.folderList'] = 2
  Capybara::Selenium::Driver.new(app, browser: :firefox, :profile => profile)
end

Capybara.default_driver    = :auto_dl
Capybara.javascript_driver = :auto_dl
Capybara.current_driver    = :auto_dl

class Scraper < Struct.new(:symbol)
  include Capybara::DSL

  @already_kissed_the_ring

  def key_ratios
    visit "/ratios/r.html?t=#{symbol}"
    find(".export_list_financials").all('a').last.click
  rescue 
    puts "Something happened with #key_ratios #{symbol}"
  end

  def income_statement(type = :qtr)
    get_statement "/income-statement/is.html?t=", type
  rescue 
    puts "Something happened with #income_statement #{symbol}"
  end

  def balance_sheet(type = :qtr)
    get_statement "/balance-sheet/bs.html?t=", type
  rescue 
    puts "Something happened with #balance_sheet #{symbol}"
  end

  def cash_flow(type = :qtr)
    get_statement "/cash-flow/cf.html?t=", type
  rescue 
    puts "Something happened with #cash_flow #{symbol}"
  end

  def statements(type)
    income_statement(type)
    balance_sheet(type)
    cash_flow(type)
    key_ratios
  end

  def get_statement(url_stub, type)
    visit "#{url_stub}#{symbol}"

    # Click the Statement Type" drop-down
    el = all("#menu_A").first
    links = el.all('a')
    links.first.click

    if type == :yr
      # Click the Annual option in the dropdown overlay
      all(:xpath, '//a[text()="Annual"]').last.click
    else
      # Click the Quarterly option in the dropdown overlay
      find('a', text: /quarterly/i).click   
    end

    # Click the export link
    within(".icon_1_span") do
      click_link('')
    end
  end
end
if __FILE__ == $0
  $*.each do |symbol| 
    [:yr, :qtr].each do |type| 
      puts "#{symbol} #{type}"
      Scraper.new(symbol).statements(type)
    end
  end
end
