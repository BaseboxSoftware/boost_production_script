require "rspec"
require_relative "testing_bot_driver"
require "pry"

RSpec.configure do |config|
  config.around(:all) do |regression_test|
    Dir[File.dirname(__FILE__) + "/pages/*.rb"].each {|file| require file }
    Dir[File.dirname(__FILE__) + "/clients/*.rb"].each {|file| require file }
    Dir[File.dirname(__FILE__) + "/helpers/*.rb"].each {|file| require file }

    @driver = TestingBotDriver.new_driver
    @wait = Selenium::WebDriver::Wait.new(:timeout => 15)

    target_size = Selenium::WebDriver::Dimension.new(1440, 900)
    @driver.manage.window.size = target_size

    begin
      regression_test.run
    ensure
      @driver.quit
    end
  end
end

def mindbody_sections_obj
  [
    {
      table_name: 'Mindbody Web Management',
      column: 'Instruction Type',
      value: 'live',
      iFrame_id: 'liveinstruction-frame',
      navbar_link: 'nav-menu-item-3271',
      wordpress_gallery_title_field: "Class Name",
      wordpress_gallery_desc_field: "Site Description"
    },
    {
      table_name: 'Mindbody Web Management',
      column: 'Instruction Type',
      value: 'virtual',
      iFrame_id: 'virtualinstruction-frame',
      navbar_link: 'nav-menu-item-3271',
      wordpress_gallery_title_field: "Class Name",
      wordpress_gallery_desc_field: "Site Description"
    }
  ]
end

def jackrabbit_sections_obj
  [
    {
      table_name: 'Jackrabbit Web Management',
      column: 'Category 2',
      value: 'Toddler',
      iFrame_id: 'toddler-frame',
      navbar_link: 'nav-menu-item-3272',
      wordpress_gallery_title_field: "Category 3",
      wordpress_gallery_desc_field: "Site Description"
    },
    {
      table_name: 'Jackrabbit Web Management',
      column: 'Category 2',
      value: 'Gymnastics',
      iFrame_id: 'gymnastics-frame',
      navbar_link: 'nav-menu-item-3272',
      wordpress_gallery_title_field: "Category 3",
      wordpress_gallery_desc_field: "Site Description"
    },
    {
      table_name: 'Jackrabbit Web Management',
      column: 'Category 2',
      value: 'Tumbling',
      iFrame_id: 'tumbling-frame',
      navbar_link: 'nav-menu-item-3272',
      wordpress_gallery_title_field: "Category 3",
      wordpress_gallery_desc_field: "Site Description"
    },
    {
      table_name: 'Jackrabbit Web Management',
      column: 'Category 2',
      value: 'Boys',
      iFrame_id: 'boys-frame',
      navbar_link: 'nav-menu-item-3272',
      wordpress_gallery_title_field: "Category 3",
      wordpress_gallery_desc_field: "Site Description"
    },
    {
      table_name: 'Jackrabbit Web Management',
      column: 'Category 2',
      value: 'Camp',
      iFrame_id: 'camp-frame',
      navbar_link: 'nav-menu-item-3272',
      wordpress_gallery_title_field: "Category 3",
      wordpress_gallery_desc_field: "Site Description"
    }
  ]
end


# Assert that after importing from specx table, and refreshing, all editied rows
# have expected value
def assert_on_expected_obj(expected, rows)
  rows.each do |row|
    expect(expected[row.keys.first]).to eq(row.values.first)
  end
end

def assert_on_iFrame_content_and_modals(expected, section_to_test)

  iFrame_id = section_to_test[:iFrame_id]
  gallery_title_field = section_to_test[:wordpress_gallery_title_field]
  gallery_desc_field = section_to_test[:wordpress_gallery_desc_field]

  @driver.switch_to.frame(iFrame_id)

  assert_on_gallery_content(expected, gallery_title_field, gallery_desc_field)

  assert_on_modal_content(iFrame_id)

end

def assert_on_modal_content(iFrame_id)
  puts "Asserting on modal content"
  learn_more_buttons = @driver.iFrame_learn_more_buttons

  # Confirms that the loop below will run below else fail
  expect(learn_more_buttons.length > 0).to eq(true)

  # Assert on modal content
  learn_more_buttons.each_with_index do |button, index|

    # Wait until frame is switched to iFrame
    @wait.until{ @driver.iFrame_modals.length > 0 }

    button.click # open modal

    # Get the title and content of the current modal being evaluated within the iFrame
    iFrame_title = @driver.iFrame_modal_headers(index)
    iFrame_body = @driver.iFrame_modal_bodies(index)

    # Exit iFrame to assert on modal on page
    @driver.switch_to.default_content

    # Wait until frame is switched to default
    @wait.until{ @driver.wordpress_modal.displayed? }

    # Get the text that is sent to the modal outside the iFrame
    wordpress_title = @driver.wordpress_modal_header
    wordpress_body = @driver.wordpress_modal_body

    # Assert that the content of the iFrame is the same as what is sent to the page
    expect(wordpress_title).to eq(iFrame_title)
    expect(wordpress_body).to eq(iFrame_body)

    @driver.close_wordpress_modal

    sleep(1) # Wait for modal to close

    @driver.switch_to.frame(iFrame_id) #Switch back to the iFrame
  end
end

def assert_on_gallery_content(expected, gallery_title_field, gallery_desc_field)
  puts "Asserting on gallery content"

  @wait.until {
    @driver.iFrame_gallery_items.length > 0
  }

  gallery_items = @driver.iFrame_gallery_items

  num_items = expected.length < 25 ? expected.length : 25

  # Confirms that the loop below will run below else fail
  expect(gallery_items.length).to eq(num_items)

  # Assume expected in correct order from 'order' property
  gallery_items.each_with_index do |item, index|
    title = item.find_elements(:css, 'p')[0].text
    description = item.find_elements(:css, 'p')[1].text

    expected_title = expected[index].values.first[gallery_title_field.to_sym][:value]
    expected_description = expected[index].values.first[gallery_desc_field.to_sym][:value]

    expect(expected_title).to eq(title)
    expect(expected_description).to eq(description)
  end
end
