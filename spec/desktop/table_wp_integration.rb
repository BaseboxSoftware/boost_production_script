require "spec_helper"

describe "SpecX" do

  it "can make random edits to a specx table, import and reflect changes on boost wordpress" do

    table_to_test = ['Mindbody Web Management', 'Jackrabbit Web Management'].sample

    @driver.navigate.to TestingBotDriver.specx_client_endpoint(SpecxApi.basebox_ip)

    @driver.specx_login("user@example.com", "password")

    @driver.select_specx_sidebar_item_by_href('table')

    # Window handle for specx client
    specx_window_handle = @driver.window_handles.first

    # @driver.open_specx_table_window(section_to_test[:table_name])
    table_window_handle = @driver.open_specx_table_window(table_to_test)

    table = @driver.randomize_table_actions
    expected = table.get_expected_obj

    rows = table.get_rows_to_assert_against(expected)

    puts "Asserting on imports"
    assert_on_expected_obj(expected, rows) # Test that after import all rows of table are correct

    sections_to_test = []
    case table_to_test
    when 'Mindbody Web Management'
      sections_to_test = mindbody_sections_obj
    when 'Jackrabbit Web Management'
      sections_to_test = jackrabbit_sections_obj
    end

    # Open up the Bost site
    @driver.execute_script( "window.open()" )
    @driver.switch_to.window(@driver.window_handles.last)
    @driver.navigate.to TestingBotDriver.boost_endpoint

    sections_to_test.each do |section|
      # Switch back to the table and get the rows for the wp section to test
      @driver.switch_to.window(table_window_handle)
      gallery_rows_to_check = table.get_rows_for_gallery(section)

      # Switch back to the Boost site
      @driver.switch_to.window(@driver.window_handles.last)

      @wait.until {
        element = @driver.navbar_link(section[:navbar_link])
        element if element.displayed?
      }.click

      # Sleeping to wait on scrolling event
      sleep 3

      assert_on_iFrame_content_and_modals(gallery_rows_to_check, section)
    end

  end
end
