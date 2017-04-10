require "spec_helper"

describe "SpecX" do

  it "can make random edits to a specx table, import and reflect changes on boost wordpress" do

    section_to_test = get_obj_to_assert_on

    @driver.navigate.to TestingBotDriver.specx_client_endpoint(SpecxApi.basebox_ip)

    @driver.specx_login("user@example.com", "password")

    @driver.select_specx_sidebar_item_by_href('table')

    # Window handle for specx client
    specx_window_handle = @driver.window_handles.first

    @driver.open_specx_table_window(section_to_test[:table_name])

    expected = @driver.make_random_specx_table_edits(section_to_test)

    rows = @driver.get_rows_to_assert_against(expected)

    puts "Asserting on imports"
    assert_on_expected_obj(expected, rows) # Test that after import all rows of table are correct

    gallery_rows_to_check = @driver.get_rows_for_gallery(section_to_test)

    @driver.close_specx_table_window(specx_window_handle)

    @driver.navigate.to TestingBotDriver.boost_endpoint

    @wait.until {
      element = @driver.navbar_link(section_to_test[:navbar_link])
      element if element.displayed?
    }.click

    # Sleeping to wait on scrolling event
    sleep 3

    assert_on_iFrame_content_and_modals(gallery_rows_to_check, section_to_test)
  end
end
