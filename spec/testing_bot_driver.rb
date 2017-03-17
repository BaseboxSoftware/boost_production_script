require "selenium/webdriver"

module TestingBotDriver
  class << self
    def endpoint
      "http://playground.phatmagnet.com/boost/"
    end

    def new_driver
      Selenium::WebDriver.for :chrome
    end
  end
end
