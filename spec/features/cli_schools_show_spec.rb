# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis schools show" do
  context "with just a URN" do
    it "displays the school details" do
      given_a_school_exists
      when_i_run_the_command
      then_the_school_details_are_displayed
    end
  end

  context "with the --id option" do
    it "finds the school with the id" do
      given_a_school_exists
      when_i_run_the_command_with_the_id_option
      then_the_school_details_are_displayed
    end
  end

  context "with the --any-site option" do
    it "finds all the school sites with the URN" do
      given_a_school_with_sites_exists
      when_i_run_the_command_with_the_any_site_option
      then_the_school_details_with_sites_are_displayed
    end
  end

  def given_a_school_exists
    @school = create(:school, name: "Test School", urn: "123456")
  end

  def given_a_school_with_sites_exists
    @school = create(:school, name: "Test School", urn: "123456")
    @site = create(:school, name: "Site B", urn: "123456", site: "B")
  end

  def when_i_run_the_command
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(arguments: %w[schools show] + [@school.urn])
      end
  end

  def when_i_run_the_command_with_the_id_option
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: %w[schools show --id] + [@school.id]
        )
      end
  end

  def when_i_run_the_command_with_the_any_site_option
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: %w[schools show --any-site] + [@school.urn]
        )
      end
  end

  def then_the_school_details_are_displayed
    expect(@output).to match(/name: Test School/)
    expect(@output).to match(/urn: 123456/)
  end

  def then_the_school_details_with_sites_are_displayed
    expect(@output).to match(/name: Test School/)
    expect(@output).to match(/urn: 123456/)
    expect(@output).to match(/site: B/)
  end
end
