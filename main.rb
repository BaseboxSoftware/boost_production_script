require "selenium-webdriver"
require "pry"

class Main
  LOAD_DIR = []
  def initialize(opts = {})
    Dir[File.dirname(__FILE__) + '/scripts/*.rb'].each {|file| require file }
    Dir[File.dirname(__FILE__) + '/pages/*.rb'].each {|file| require file }
    @type = ARGV[0] || "work_flow"
    @browser = ARGV[1]&.to_sym || :chrome
    start_script
  end

  @@home_url = 'http://playground.phatmagnet.com/boost/'

  def self.home_url
    @@home_url
  end

  def start_script
    driver = Selenium::WebDriver.for @browser
    driver.navigate.to @@home_url

    case @type
    when "work_flow"
      WorkFlow.new(driver: driver)
    end
  end
end

Main.new
