# frozen_string_literal: true

describe "mavis generate cohort-imports" do
  it "generates a cohort import CSV file" do
    given_an_organisation_exists
    and_there_are_three_sessions_in_the_organisation
    when_i_run_the_generate_cohort_imports_command
    then_a_cohort_import_csv_file_is_created
  end

  def given_an_organisation_exists
    @programme = Programme.hpv.first || create(:programme, :hpv)
    @organisation = create(:organisation, ods_code: "R1Y")
  end

  def and_there_are_three_sessions_in_the_organisation
    @sessions =
      create_list(
        :session,
        3,
        organisation: @organisation,
        programmes: [@programme]
      )
  end

  def when_i_run_the_generate_cohort_imports_command
    freeze_time do
      @output =
        capture_output do
          Dry::CLI.new(MavisCLI).call(
            arguments: %w[generate cohort-imports -o R1Y -p 100]
          )
        end
      @timestamp = Time.current.strftime("%Y%m%d%H%M%S")
    end
  end

  def then_a_cohort_import_csv_file_is_created
    expect(@output).to include(
      "Generating cohort import for ods code R1Y with 100 patients"
    )
    expect(@output).to match(
      /Cohort import CSV generated:.*cohort-import-R1Y-hpv-100-#{@timestamp}.csv/
    )

    expect(
      File.readlines(
        Rails.root.join("tmp", "cohort-import-R1Y-hpv-100-#{@timestamp}.csv")
      ).length
    ).to eq 101
  end
end
