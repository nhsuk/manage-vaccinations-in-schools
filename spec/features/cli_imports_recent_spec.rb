# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis imports recent" do
  scenario "shows both class and cohort imports by default" do
    given_there_are_class_and_cohort_imports
    when_i_run_the_recent_patient_imports_command
    then_i_should_see_both_import_types
  end

  scenario "filters to show only class imports" do
    given_there_are_class_and_cohort_imports
    when_i_run_the_command_filtered_by_type("class")
    then_i_should_see_only_class_imports
  end

  scenario "filters to show only cohort imports" do
    given_there_are_class_and_cohort_imports
    when_i_run_the_command_filtered_by_type("cohort")
    then_i_should_see_only_cohort_imports
  end

  scenario "limits the number of imports shown across both types" do
    given_there_are_multiple_class_and_cohort_imports
    when_i_run_the_command_with_a_number_limit
    then_i_should_see_limited_patient_imports
  end

  scenario "filters by organisation across both import types" do
    given_there_are_imports_in_different_organisations
    when_i_run_the_command_filtered_by_organisation
    then_i_should_see_imports_for_that_organisation_only
  end

  scenario "filters by workgroup across both import types" do
    given_there_are_imports_in_different_workgroups
    when_i_run_the_command_filtered_by_workgroup
    then_i_should_see_imports_for_that_workgroup_only
  end

  scenario "sorts imports by created_at across both types" do
    given_there_are_interleaved_class_and_cohort_imports
    when_i_run_the_recent_patient_imports_command
    then_i_should_see_imports_sorted_by_creation_date
  end

  def given_there_are_class_and_cohort_imports
    @team = create(:team, workgroup: "test_team")
    @location = create(:school, team: @team)

    @class_import =
      create(
        :class_import,
        :processed,
        team: @team,
        location: @location,
        rows_count: 15
      )
    @cohort_import =
      create(:cohort_import, :processed, team: @team, rows_count: 25)
  end

  def given_there_are_multiple_class_and_cohort_imports
    @team = create(:team, workgroup: "multi_team")
    @location = create(:school, team: @team)

    # Create 3 of each type with time travel to ensure proper ordering
    freeze_time do
      @class_import1 =
        create(
          :class_import,
          :processed,
          team: @team,
          location: @location,
          rows_count: 10
        )
      travel 1.minute
      @class_import2 =
        create(
          :class_import,
          :processed,
          team: @team,
          location: @location,
          rows_count: 20
        )
      travel 1.minute
      @class_import3 =
        create(
          :class_import,
          :processed,
          team: @team,
          location: @location,
          rows_count: 30
        )
      travel 1.minute
      @cohort_import1 =
        create(:cohort_import, :processed, team: @team, rows_count: 40)
      travel 1.minute
      @cohort_import2 =
        create(:cohort_import, :processed, team: @team, rows_count: 50)
      travel 1.minute
      @cohort_import3 =
        create(:cohort_import, :processed, team: @team, rows_count: 60)
    end
  end

  def given_there_are_imports_in_different_organisations
    @organisation1 = create(:organisation, ods_code: "ORG1")
    @organisation2 = create(:organisation, ods_code: "ORG2")
    @team1 = create(:team, organisation: @organisation1, workgroup: "team1")
    @team2 = create(:team, organisation: @organisation2, workgroup: "team2")
    @location1 = create(:school, team: @team1)

    @class_import_org1 =
      create(
        :class_import,
        :processed,
        team: @team1,
        location: @location1,
        rows_count: 15
      )
    @cohort_import_org1 =
      create(:cohort_import, :processed, team: @team1, rows_count: 25)
    @cohort_import_org2 =
      create(:cohort_import, :processed, team: @team2, rows_count: 35)
  end

  def given_there_are_imports_in_different_workgroups
    @organisation = create(:organisation)
    @team1 = create(:team, organisation: @organisation, workgroup: "alpha")
    @team2 = create(:team, organisation: @organisation, workgroup: "beta")
    @location1 = create(:school, team: @team1)

    @class_import_alpha =
      create(
        :class_import,
        :processed,
        team: @team1,
        location: @location1,
        rows_count: 15
      )
    @cohort_import_alpha =
      create(:cohort_import, :processed, team: @team1, rows_count: 25)
    @cohort_import_beta =
      create(:cohort_import, :processed, team: @team2, rows_count: 35)
  end

  def given_there_are_interleaved_class_and_cohort_imports
    @team = create(:team, workgroup: "interleaved")
    @location = create(:school, team: @team)

    freeze_time do
      @oldest = create(:cohort_import, :processed, team: @team, rows_count: 10)
      travel 1.hour
      @middle =
        create(
          :class_import,
          :processed,
          team: @team,
          location: @location,
          rows_count: 20
        )
      travel 1.hour
      @newest = create(:cohort_import, :processed, team: @team, rows_count: 30)
    end
  end

  def when_i_run_the_recent_patient_imports_command
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(arguments: %w[imports recent --once])
      end
  end

  def when_i_run_the_command_filtered_by_type(type)
    type_option =
      case type
      when "class"
        "--class-imports"
      when "cohort"
        "--cohort-imports"
      else
        raise ArgumentError, "Invalid type: #{type}"
      end

    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: ["imports", "recent", "--once", type_option]
        )
      end
  end

  def when_i_run_the_command_with_a_number_limit
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: %w[imports recent --once --number 3]
        )
      end
  end

  def when_i_run_the_command_filtered_by_organisation
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: %w[imports recent --once --organisations ORG1]
        )
      end
  end

  def when_i_run_the_command_filtered_by_workgroup
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: %w[imports recent --once --workgroups alpha]
        )
      end
  end

  def then_i_should_see_both_import_types
    # Check for both types (may be truncated as "cla" and "coh")
    expect(@output).to match(/\bcla/)
    expect(@output).to match(/\bcoh/)
    expect(@output).to match(/\b15\b/)
    expect(@output).to match(/\b25\b/)
    expect(@output).to match(/tes/) # test_team may be truncated
  end

  def then_i_should_see_only_class_imports
    # Check for class import rows (may show as "cla")
    expect(@output).to match(/\bcla/)
    expect(@output).to match(/\b15\b/)
    # Count data lines that don't include "coh" (cohort imports)
    data_lines =
      @output.lines.reject do |line|
        line.include?("╭") || line.include?("╰") || line.include?("type")
      end
    cohort_lines = data_lines.select { |line| line.match?(/\bcoh/) }
    expect(cohort_lines.count).to eq(0)
  end

  def then_i_should_see_only_cohort_imports
    # Check for cohort import rows (may show as "coh")
    expect(@output).to match(/\bcoh/)
    expect(@output).to match(/\b25\b/)
    # Count data lines that don't include "cla" (class imports)
    data_lines =
      @output.lines.reject do |line|
        line.include?("╭") || line.include?("╰") || line.include?("type")
      end
    class_lines = data_lines.select { |line| line.match?(/\bcla/) }
    expect(class_lines.count).to eq(0)
  end

  def then_i_should_see_limited_patient_imports
    # Should show the 3 most recent imports across both types
    lines = @output.lines
    # Count lines that contain actual data (exclude header/border lines)
    # May be truncated as "mul" or "multi"
    data_lines = lines.select { |line| line.match?(/\bmul/) }
    expect(data_lines.count).to eq(3)

    # The 3 newest should be cohort_import3, cohort_import2, cohort_import1
    expect(@output).to match(/\b60\b/)
    expect(@output).to match(/\b50\b/)
    expect(@output).to match(/\b40\b/)
  end

  def then_i_should_see_imports_for_that_organisation_only
    expect(@output).to include("ORG1")
    expect(@output).to match(/tea/) # team1 may be truncated
    expect(@output).not_to include("ORG2")
    # Should see both class and cohort imports from ORG1
    expect(@output).to match(/\bcla/)
    expect(@output).to match(/\bcoh/)
  end

  def then_i_should_see_imports_for_that_workgroup_only
    expect(@output).to match(/alp/) # alpha may be truncated
    expect(@output).not_to match(/bet/) # beta should not appear
    # Should see both class and cohort imports from alpha workgroup
    expect(@output).to match(/\bcla/)
    expect(@output).to match(/\bcoh/)
  end

  def then_i_should_see_imports_sorted_by_creation_date
    # May be truncated as "int" or "inter"
    lines = @output.lines.select { |line| line.match?(/\bint/) }

    # The order should be newest first (cohort 30), then middle (class 20), then oldest (cohort 10)
    # All three should appear in the output
    expect(lines.join("\n")).to match(/\b30\b/)
    expect(lines.join("\n")).to match(/\b20\b/)
    expect(lines.join("\n")).to match(/\b10\b/)

    # Extract the rows values from data lines
    # The table format is: │ type  id  created…  processed…  rows  ods  ...
    rows_values = []
    lines.each do |line|
      # Skip header and border lines
      if line.include?("╭") || line.include?("╰") || line.include?("type") ||
           line.strip.start_with?("│ type")
        next
      end

      # Extract all numbers from the line
      numbers = line.scan(/\b\d+\b/).map(&:to_i)
      # The rows value should be in the list - looking for 10, 20, or 30
      rows_val = numbers.find { |n| [10, 20, 30].include?(n) }
      rows_values << rows_val if rows_val
    end

    # Since they're created newest first: 30, 20, 10
    expect(rows_values).to eq([30, 20, 10])
  end
end
