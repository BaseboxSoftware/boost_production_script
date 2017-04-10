module SpecxGalleryIframe
  class ::Selenium::WebDriver::Driver
    def iFrame_learn_more_buttons
      self.find_elements(:css, '.card > a')
    end

    def iFrame_modals
      self.find_elements(:css, '.modal')
    end

    def iFrame_modal_headers(index)
      self.iFrame_modals[index].find_element(:css, '.modal-header > b').attribute('innerHTML')
    end

    def iFrame_modal_bodies(index)
      self.iFrame_modals[index].find_element(:css, '.modal-body').attribute('innerHTML')
    end

    def iFrame_gallery_items
      self.find_elements(:css, '.mt-card-content')
    end

    def wordpress_modal
      self.find_element(:css, '#modal-replace')
    end

    def wordpress_modal_header
      self.find_element(:css, '#modal-replace > .modal-content > .modal-header > b').text
    end

    def wordpress_modal_body
      self.find_element(:css, '#modal-replace > .modal-content > .modal-body').attribute('innerHTML')
    end

    def close_wordpress_modal
      self.find_element(:css, '#modal-replace > .modal-content > .modal-header > a > .modal-close').click
    end
  end
end
