
class WorkFlow
  def initialize(opts = {})
      puts "Starting WorkFlow..."
      @driver = opts[:driver]
      execute
      @driver.quit
  end

  def execute
    @driver.classes_link.click
  end
end
