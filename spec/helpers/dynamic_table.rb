module SpecxClient
  class DynamicTable
    def initialize(driver)
      # Create client for Specx API
      @client = SpecxApi.new

      @driver = driver

      # Object of all changes to be asserted against
      @expected_obj = {}
      @table_json = get_table_json
      @column_headers_obj = create_column_headers_obj
      @exisisting_text_attribution_values_obj = create_exisiting_text_attribution_values_obj
    end

    def get_expected_obj
      except_nested(@expected_obj, :value_field)
    end

    def random_filter
      column_to_filter = @column_headers_obj.sample
      filter_val = ""
      case column_to_filter[:datatype]
      when "text"
        filter_val = @exisisting_text_attribution_values_obj[column_to_filter[:title].to_sym].sample
      when 'boolean'
        filter_val = ["true", "false"].sample
      when 'number'
        filter_val = rand(5)
      else
        raise 'Datatype not supported'
      end

      filter_column(column_to_filter[:title], filter_val)
    end

    def filter_column(column, value)
      puts "Filtering column: #{column} by: #{value}"
      puts
      column_to_filter = @column_headers_obj.select{|x| x[:title] == column}.first
      filter_field = column_to_filter[:filter_field]
      filter_field.send_keys value
      filter_field.send_keys(:enter)

      wait_for_table
    end

    def random_sort
      column_to_sort = @column_headers_obj.sample
      sort_by = [:sort_ascending, :sort_descending].sample

      puts "Sorting column: #{column_to_sort[:title]} by: #{sort_by}"
      puts
      @driver.execute_script("arguments[0].click(true);", column_to_sort[sort_by])

      wait_for_table
    end

    # Make random changes to a specx table that driver is pointed at
    # Return the object of expected changes to assert on wordpress site
    # If driver is not pointed at an open table this will not work
    def make_random_specx_table_edits
      visible_rows_obj = create_visible_rows_obj

      # Randomally select rows to edits
      rows_to_edit = visible_rows_obj.sample(rand(1..visible_rows_obj.length))

      make_row_edits(rows_to_edit)

      # Return @expected_obj without :value_field
      except_nested(@expected_obj, :value_field)
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

      puts "Editing ID: #{row_identifier}"
      puts "Changing value in #{col_obj[:title]}"
      puts "From: #{row_item[:value]}"

      case datatype
      when 'text' then
        row_item[:value_field].clear
        new_val = @exisisting_text_attribution_values_obj[col_title].sample
        row_item[:value_field].send_keys new_val
        puts "To: #{new_val}"
        puts
        new_val
      when 'boolean' then
        @driver.execute_script("arguments[0].click(true);", row_item[:value_field])
        new_val = row_item[:value] == 'true' ? 'false' : 'true' # Return the toggled value
        puts "To: #{new_val}"
        puts
        new_val
      when 'number' then
        row_item[:value_field].clear
        new_num = rand(1..5).to_s
        row_item[:value_field].send_keys new_num
        puts "To: #{new_num}"
        puts
        new_num
      else
        raise "Editing on this datatype not yet supported"
      end
    end

    def import
      @driver.find_element(:css, '#import-changes-btn').click
      puts "Importing"
      puts
      sleep 60
    end

    def refresh_table
      @driver.navigate.refresh
      wait_for_table
    end

    def scroll_to_expand_table
      @driver.find_elements(:css, 'table > tbody > tr').last.location_once_scrolled_into_view
      sleep 1
    end

    # Create array of column header objects with title and input filter field
    def create_column_headers_obj
      @column_headers_obj = []
      column_titles = @driver.find_elements(:css, 'table > thead > tr').first.find_elements(:css, 'th').select{|x| x.find_element(:css, 'span:nth-child(1)')}.map{|x| x.text}
      column_filter_fields = @driver.find_elements(:css, 'table > thead > tr').last.find_elements(:css, 'th > input')
      sort_ascending_btns = @driver.find_elements(:css, 'table > thead > tr').first.find_elements(:css, '.arrow-up')
      sort_descending_btns = @driver.find_elements(:css, 'table > thead > tr').first.find_elements(:css, '.arrow-down')
      column_titles.each_with_index do |title, index|
        obj = {
          title: title,
          filter_field: column_filter_fields[index],
          sort_ascending: sort_ascending_btns[index],
          sort_descending: sort_descending_btns[index],
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

      visible_row_web_elements = @driver.find_elements(:css, 'table > tbody > tr')

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
    # All finder columns MUST be on table
    def get_finder_value(columns)
      finder_val = ""
      @table_json["finder_columns"].each do |finder|
        finder_val += columns[finder.to_sym][:value]
      end
      finder_val
    end

    # Get the table json from SpecX API
    def get_table_json
      url = @driver.current_url
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

    def clear_filters
      @driver.find_element(:css, '#clear-filters-btn').click

      wait_for_table
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

    def get_rows_to_assert_against(expected)
      refresh_table
      rows = create_visible_rows_obj # Get all the visible rows
      visible_keys = rows.map{|x| x.keys.first}

      # Check that all the rows to assert against are visible, otherwise scroll to get more rows
      diff = expected.keys - visible_keys

      puts 'Searching table for rows to assert against'
      puts

      # Keep getting rows untill all the rows to assert against are visible
      # If stuck in infinite loop, then increase sleep after import
      while diff.any?
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
      refresh_table
      filter_column(section_to_test[:column], section_to_test[:value])
      filter_column('Website', 'true')
      rows = create_visible_rows_obj
      except_nested(rows, :value_field)
    end

    def wait_for_table
      @driver.wait.until{
        @driver.find_element(:css, '.table-scrollable').displayed?
      }

      # Refresh web elements in @column_headers_obj after refresh
      @column_headers_obj = create_column_headers_obj
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

    def create_array_of_faker_values
      values = []
      50.times do
        values << Faker::RickAndMorty.quote
      end
      values
    end
  end
end
