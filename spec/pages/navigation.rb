module Navigation
  class ::Selenium::WebDriver::Driver
    def navbar_link(link_id)
      self.find_element(:id, link_id)
    end
  end
end
