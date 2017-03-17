require "rspec"
require_relative "testing_bot_driver"
require "pry"

RSpec.configure do |config|
  config.around(:example) do |example|
    Dir[File.dirname(__FILE__) + "/pages/*.rb"].each {|file| require file }

    @driver = TestingBotDriver.new_driver
    @wait = Selenium::WebDriver::Wait.new(:timeout => 15)

    target_size = Selenium::WebDriver::Dimension.new(1440, 900)
    @driver.manage.window.size = target_size

    @driver.navigate.to TestingBotDriver.endpoint

    begin
      example.run
    ensure
      @driver.quit
    end
  end
end
