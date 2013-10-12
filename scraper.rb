require 'rubygems'
require 'capybara'
require 'capybara/dsl'
require "selenium-webdriver"

Capybara.run_server = false
Capybara.app_host = 'http://financials.morningstar.com'

mimes = [
  "text/plain",
  "application/csv",
  "application/vnd.ms-excel",
  "text/csv",
  "text/html",
  "text/comma-separated-values",
  "application/octet-stream",
]

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
  end

  def income_statement(type = :qtr)
    get_statement "/income-statement/is.html?t=", type
  end

  def balance_sheet(type = :qtr)
    get_statement "/balance-sheet/bs.html?t=", type
  end

  def cash_flow(type = :qtr)
    get_statement "/cash-flow/cf.html?t=", type
  end

  def statement(type)
    income_statement(type)
#    balance_sheet(type)
#    cash_flow(type)
#    key_ratios
  end

  def get_statement(url_stub, type)
    visit "#{url_stub}#{symbol}"

    # Decide on yearly verses quarterly
    el = all("#menu_A").first
p el
    if el
      links = el.all('a')
      links.first.click

      link_i = type == :yr ? 0 : 1
      p link_i
      p links
      p links.elements.length
      links.].click
    end

    within(".icon_1_span") do
      click_link('')
    end
  end
end
%w[OUTR].each do |symbol| 
  [:yr, :qtr].each {|type| Scraper.new(symbol).statement(type)}
end

