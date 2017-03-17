module SpecxGalleryIframe
  class ::Selenium::WebDriver::Driver
    def learn_more_buttons
      self.find_elements(:css, '.card > a')
    end

    def modal_header
      self.find_element(:css, '.modal-header > b')
    end

    def modal_close
      self.find_element(:css, '.modal-close')
    end
  end
end
