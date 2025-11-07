# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis schools add-programme-year-group" do
  context "when the school doesn't exist" do
    it "displays an error message" do
      when_i_run_the_command_expecting_an_error
      then_a_school_not_found_error_message_is_displayed
    end
  end

  context "when the programme doesn't exist" do
    it "displays an error message" do
      given_the_school_exists

      when_i_run_the_command_with_invalid_programme
      then_a_programme_not_found_error_message_is_displayed
    end
  end

  context "when the school and programme exists" do
    it "runs successfully" do
      given_the_school_exists
      and_the_programme_exists

      when_i_run_the_command
      then_the_year_groups_are_added_to_the_school
    end
  end

  private

  def command
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[schools add-programme-year-group 123456 flu 12 13 14]
    )
  end

  def command_with_invalid_programme
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[schools add-programme-year-group 123456 invalid 12 13 14]
    )
  end

  def given_the_school_exists
    @school = create(:school, urn: "123456")
  end

  def and_the_programme_exists
    @programme = CachedProgramme.flu
  end

  def when_i_run_the_command
    @output = capture_output { command }
  end

  def when_i_run_the_command_expecting_an_error
    @output = capture_error { command }
  end

  def when_i_run_the_command_with_invalid_programme
    @output = capture_error { command_with_invalid_programme }
  end

  def then_a_school_not_found_error_message_is_displayed
    expect(@output).to include("Could not find school.")
  end

  def then_a_programme_not_found_error_message_is_displayed
    expect(@output).to include("Could not find programme.")
  end

  def then_the_year_groups_are_added_to_the_school
    year_groups =
      @school
        .location_programme_year_groups
        .where(programme: @programme)
        .pluck_year_groups

    expect(year_groups).to contain_exactly(12, 13, 14)
  end
end
