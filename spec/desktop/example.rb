require "spec_helper"

describe "Classes Page" do
  it "can open all modals and check titles" do
    @wait.until {
      element = @driver.classes_link
      element if element.displayed?
    }.click

    @wait.until {
      element = @driver.live_instruction_link
      element if element.displayed?
    }.click

    # Sleeping to wait on scrolling event
    sleep 3

    @driver.switch_to.frame("liveinstruction-frame")

    learn_more_buttons = @driver.learn_more_buttons

    # Confirms that the loop below will run below else fail
    expect(learn_more_buttons.length > 0).to eq(true)

    @driver.learn_more_buttons.each do |button|
      # open modal
      button.click

      modal_text = @wait.until {
        element = @driver.modal_header
        element if element.displayed?
      }.text

      expect(modal_text).to eq('Body Pump')

      # close modal
      @driver.modal_close
    end
  end
end
