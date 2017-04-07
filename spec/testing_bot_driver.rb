require "selenium/webdriver"

module TestingBotDriver
  class << self
    def boost_endpoint
      "http://192.168.0.104/boost"
    end

    def specx_client_endpoint(ip)
      "http://#{ip}/admin/login"
    end

    def new_driver
      Selenium::WebDriver.for :chrome
    end
  end
end
