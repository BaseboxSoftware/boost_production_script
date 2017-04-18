require "faker"

module SpecxClient
  class ::Selenium::WebDriver::Driver

    def wait
      Selenium::WebDriver::Wait.new(:timeout => 15)
    end

    def specx_login(username, password)
      self.find_element(:css, '#email').send_keys username
      self.find_element(:css, '#password').send_keys password
      self.find_element(:css, '.spin-button').click

      # Wait for login to complete
      self.wait.until{
        self.find_element(:css, '#drawer').displayed?
      }
    end

    # Select Specx sidebar item by href
    def select_specx_sidebar_item_by_href(sidebar_item)
      self.find_element(:css, "a[href*='#{sidebar_item}']").click
    end

    # Open a drawer item by bame
    def open_specx_drawer_item(item_name)
      self.find_elements(:css, '.list-group-item .item-title').select{|x| x.attribute('innerHTML').to_s.strip! == item_name}.first.click
    end

    # Open a specx table and switch driver to the new window
    def open_specx_table_window(table_name)
      open_specx_drawer_item(table_name)

      self.find_element(:css, '.action-bar > a').click

      new_window_handle = self.window_handles.last
      self.switch_to.window(new_window_handle)

      self.wait.until{
        self.find_element(:css, '.table-scrollable').displayed?
      }

      new_window_handle
    end

    # Build expected object here
    def randomize_table_actions
      table = DynamicTable.new(self)

      dirty_changes = false

      (rand(10) + 1).times do
        case rand(100) + 1
        when 1..30
          if dirty_changes
            table.import
            dirty_changes = false
          end
          table.random_filter
        when 31..60
          table.make_random_specx_table_edits
          dirty_changes = true
        when 61..90
          if dirty_changes
            table.import
            dirty_changes = false
          end
          table.random_sort
        when 90..100
          table.import if dirty_changes
        end

        # Clear filters on empty search results
        if table.create_visible_rows_obj.empty?
          puts "Empty table. Clearing filters"
          table.clear_filters
        end
      end

      table.import
      table
    end

  end
end
