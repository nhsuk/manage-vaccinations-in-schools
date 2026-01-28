# frozen_string_literal: true

describe "mavis generate cohort-imports" do
  it "generates a cohort import CSV file" do
    given_an_organisation_exists
    and_there_are_three_sessions_in_the_organisation
    when_i_run_the_generate_cohort_imports_command
    then_a_cohort_import_csv_file_is_created
  end

  context "when there are multiple programme types" do
    it "generates a cohort import CSV file" do
      given_an_organisation_exists_with_multiple_programme_types
      and_there_are_three_sessions_in_the_organisation_for_multiple_programme_types
      when_i_run_the_generate_cohort_imports_command_with_multiple_programme_types
      then_a_cohort_import_csv_file_is_created_for_all_programme_types
    end
  end

  def given_an_organisation_exists
    @hpv = Programme.hpv
    @flu = Programme.flu
    @team = create(:team, workgroup: "r1y", programmes: [@hpv])
  end

  def given_an_organisation_exists_with_multiple_programme_types
    @hpv = Programme.hpv
    @flu = Programme.flu
    @team = create(:team, workgroup: "r1y", programmes: [@hpv, @flu])
  end

  def and_there_are_three_sessions_in_the_organisation
    @sessions = create_list(:session, 3, team: @team, programmes: [@hpv])
  end

  def and_there_are_three_sessions_in_the_organisation_for_multiple_programme_types
    @sessions = create_list(:session, 3, team: @team, programmes: [@hpv, @flu])
  end

  def when_i_run_the_generate_cohort_imports_command
    freeze_time do
      @output =
        capture_output do
          Dry::CLI.new(MavisCLI).call(
            arguments: %w[generate cohort-imports -w r1y -c 100]
          )
        end
      @timestamp = Time.current.strftime("%Y%m%d%H%M%S")
    end
  end

  def when_i_run_the_generate_cohort_imports_command_with_multiple_programme_types
    freeze_time do
      @output =
        capture_output do
          Dry::CLI.new(MavisCLI).call(
            arguments: %w[generate cohort-imports -w r1y -p hpv,flu -c 100]
          )
        end
      @timestamp = Time.current.strftime("%Y%m%d%H%M%S")
    end
  end

  def then_a_cohort_import_csv_file_is_created
    expect(@output).to include(
      "Generating cohort import for team r1y with 100 patients"
    )
    expect(@output).to match(
      /Cohort import CSV generated:.*cohort-import-r1y-hpv-100-#{@timestamp}.csv/
    )

    expect(
      File.readlines(
        Rails.root.join("tmp", "cohort-import-r1y-hpv-100-#{@timestamp}.csv")
      ).length
    ).to eq 101
  end

  def then_a_cohort_import_csv_file_is_created_for_all_programme_types
    expect(@output).to include(
      "Generating cohort import for team r1y with 100 patients"
    )
    expect(@output).to match(
      /Cohort import CSV generated:.*cohort-import-r1y-hpv-flu-100-#{@timestamp}.csv/
    )

    expect(
      File.readlines(
        Rails.root.join(
          "tmp",
          "cohort-import-r1y-hpv-flu-100-#{@timestamp}.csv"
        )
      ).length
    ).to eq 101
  end
end
