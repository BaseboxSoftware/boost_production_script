module Classes
  class ::Selenium::WebDriver::Driver
    def live_instruction_link
      self.find_element(:css, "a[href='#live-instruction']")
    end
  end
end
