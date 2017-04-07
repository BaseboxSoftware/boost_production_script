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
    end

    # Close the specx table window and switch driver window handle back to specx client
    def close_specx_table_window(specx_window_handle)
      self.close()
      self.switch_to.window(specx_window_handle)
    end

    # Make random changes to a specx table that driver is pointed at
    # Return the object of expected changes to assert on wordpress site
    # If driver is not pointed at an open table this will not work
    def make_random_specx_table_edits(section_to_test)
      # Create client for Specx API
      @client = SpecxApi.new

      # Object of all changes to be asserted against
      @expected_obj = {}

      @table_json = get_table_json
      @column_headers_obj = create_column_headers_obj
      @exisisting_text_attribution_values_obj = create_exisiting_text_attribution_values_obj

      filter_column(section_to_test[:column], section_to_test[:value])

      visible_rows_obj = create_visible_rows_obj

      # Randomally select rows to edits
      rows_to_edit = visible_rows_obj.sample(rand(1..visible_rows_obj.length))

      make_row_edits(rows_to_edit)

      import_changes
      refresh_table

      # Return @expected_obj without :value_field
      except_nested(@expected_obj, :value_field)
    end

    def get_rows_to_assert_against(expected)
      rows = create_visible_rows_obj # Get all the visible rows
      visible_keys = rows.map{|x| x.keys.first}

      # Check that all the rows to assert against are visible, otherwise scroll to get more rows
      diff = expected.keys - visible_keys

      # Keep getting rows untill all the rows to assert against are visible
      # If stuck in infinite loop, then increase sleep after import
      while diff.any?
        puts 'Finding rows to assert against'
        puts diff
        scroll_to_expand_table
        sleep 1

        rows = create_visible_rows_obj # Get all the visible rows
        visible_keys = rows.map{|x| x.keys.first}

        # Check that all the rows to assert against are visible, otherwise scroll to get more rows
        diff = expected.keys - visible_keys
      end

      # Get the rows that were previously edited
      rows_to_check = rows.select{|x| expected.keys.include? x.keys.first}
      except_nested(rows_to_check, :value_field) # Return the rows without :value_field
    end

    # Only returning max 25 right now because Gallery only set to show 25
    # Returns the top 25 rows on the website in order by order property by default
    def get_rows_for_gallery(section_to_test)
      filter_column(section_to_test[:column], section_to_test[:value])
      filter_column('Website', 'on')
      rows = create_visible_rows_obj
      except_nested(rows, :value_field)
    end

    private

    # Create array of column header objects with title and input filter field
    def create_column_headers_obj
      @column_headers_obj = []
      column_titles = self.find_elements(:css, 'table > thead > tr').first.find_elements(:css, 'th').select{|x| x.find_element(:css, 'span:nth-child(1)')}.map{|x| x.text}
      column_filter_fields = self.find_elements(:css, 'table > thead > tr').last.find_elements(:css, 'th > input')
      column_titles.each_with_index do |title, index|
        obj = {
          title: title,
          filter_field: column_filter_fields[index],
          datatype: @table_json["columns"].select{|x| x["name"] == title}.first["datatype"],
          editable: determine_if_column_is_editable(title)
        }
        @column_headers_obj << obj
      end

      @column_headers_obj
    end

    # Create array of row objects, use column headers to lable columns with the row
    def create_visible_rows_obj
      visible_rows_obj = []

      visible_row_web_elements = self.find_elements(:css, 'table > tbody > tr')

      visible_row_web_elements.each do |row|
        row_items = row.find_elements(:css, 'td') # Array of web elements for each column in row
        visible_rows_obj << create_row_obj(row_items)
      end
      visible_rows_obj
    end

    # Create individual row object with column information
    # Use concatenation of finder_values as key
    def create_row_obj(row_items)
      row = {}
      columns = {} # Object for each column in a single row with its values
      row_items.each_with_index do |item, column_index|
        # Match the column to its header by index of the @column_headers_obj
        column = @column_headers_obj[column_index]
        column_header = column[:title].to_sym
        columns[column_header] = {
          value: item.attribute('title'),
          value_field: column[:editable] ? get_value_field(item, column[:title]) : nil
        }
      end
      finder = get_finder_value(columns)
      row[finder] = columns
      row
    end

    # Concatenate all finder columns to get a single value
    # Finder columns MUST be on table
    def get_finder_value(columns)
      finder_val = ""
      @table_json["finder_columns"].each do |finder|
        finder_val += columns[finder.to_sym][:value]
      end
      finder_val
    end

    # Get the table json from SpecX API
    def get_table_json
      url = self.current_url
      table_id = url.split('/').last
      response = @client.table(table_id)["table"]
    end

    # If the column is a finder or template column, it is not editable
    def determine_if_column_is_editable(column)
      if (@table_json["finder_columns"].include? column) || (@table_json["template_column"] == column)
        false
      else
        true
      end
    end

    # Get the value field by datatype
    def get_value_field(item, column_title)
      datatype = @table_json["columns"].select{|x| x["name"] == column_title}.first["datatype"]
      case datatype
      when 'text'
        item.find_element(:css, 'textarea')
      when 'boolean'
        item.find_element(:css, 'span > div')
      else
        item.find_element(:css, 'input')
      end
    end

    def filter_column(column, value)
      column_to_filter = @column_headers_obj.select{|x| x[:title] == column}.first
      filter_field = column_to_filter[:filter_field]
      filter_field.send_keys value
      filter_field.send_keys(:enter)

      # Wait for filter to complete
      self.wait.until{
        self.find_element(:css, '.table-scrollable').displayed?
      }

      # Refresh web elements in @column_headers_obj after refresh
      @column_headers_obj = create_column_headers_obj
    end

    def make_row_edits(rows_to_edit)
      # Map out all columns that are editable
      columns = @column_headers_obj.map{|x| x[:title] if x[:editable] == true}.compact
      rows_to_edit.each do |row|

        columns_to_edit = columns.sample(rand(1..columns.length)) # Select random columns to edit

        row_obj = row.values.first # The values of the row without the key
        columns_to_edit.each do |col|
          # Get the associated column object
          col_obj = @column_headers_obj.select{|x| x[:title] == col}.first
          # The specific row item to edit
          row_item = row_obj[col.to_sym]
          row_id = row.key(row_obj)
          # Modify the row_obj to the same value of the cell editied on the table
          row_obj[col.to_sym][:value] = edit_cell(row_item, col_obj, row_id)
        end
        @expected_obj[row.keys.first] = row_obj # Add the edited row_obj to the expected obj
      end
    end

    # Edit a cell on the table and return the value that was edited
    def edit_cell(row_item, col_obj, row_identifier)
      datatype = col_obj[:datatype]
      col_title = col_obj[:title].to_sym
      case datatype
      when 'text' then
        row_item[:value_field].clear
        new_val = @exisisting_text_attribution_values_obj[col_title].sample
        row_item[:value_field].send_keys new_val
        new_val
      when 'boolean' then
        self.execute_script("arguments[0].click(true);", row_item[:value_field])
        row_item[:value] == 'true' ? 'false' : 'true' # Return the toggled value
      when 'number' then
        row_item[:value_field].clear
        new_num = rand(1..5).to_s
        row_item[:value_field].send_keys new_num
        new_num
      else
        raise "Editing on this datatype not yet supported"
      end
    end

    def import_changes
      self.find_element(:css, '#import-changes-btn').click
      puts "Waiting for imports to run"
      sleep 45
    end

    # Create object of exisiting text values by type
    # This will be used to make realistic random edits
    def create_exisiting_text_attribution_values_obj
      exisiting_text_attribution_values_obj = {}
      text_attributions = @column_headers_obj.map{|x| x[:title] if x[:datatype] == 'text'}.compact

      text_attributions.each do |attribute|

        response = @client.text_attribution_values_by_type(attribute)

        # If there are no values returned from specx API, use faker to get text values
        if response["values"].empty?
          exisiting_text_attribution_values_obj[attribute.to_sym] = create_array_of_faker_values
        else
          exisiting_text_attribution_values_obj[attribute.to_sym] = response["values"]
        end
      end

      exisiting_text_attribution_values_obj
    end

    # Remove nested key from object
    def except_nested(x,key)
      case x
      when Hash
        x = x.inject({}) {|m, (k, v)| m[k] = except_nested(v,key) unless k == key ; m }
      when Array
        x.map! {|e| except_nested(e,key)}
      end
      x
    end

    def refresh_table
      self.navigate.refresh
      self.wait.until{
        self.find_element(:css, '.table-scrollable').displayed?
      }

      # Refresh web elements in @column_headers_obj after refresh
      @column_headers_obj = create_column_headers_obj
    end

    def scroll_to_expand_table
      self.find_elements(:css, 'table > tbody > tr').last.location_once_scrolled_into_view
      sleep 1
    end

    def create_array_of_faker_values
      values = []
      50.times do
        values << Faker::RickAndMorty.quote
      end
      values
    end

  end
end
