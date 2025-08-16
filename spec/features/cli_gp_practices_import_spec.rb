# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis gp-practices import" do
  it "imports GP practices from a file" do
    given_a_gp_practices_file_exists
    when_i_run_the_import_command
    then_gp_practices_are_imported_correctly
  end

  def given_a_gp_practices_file_exists
    # Nothing to do here, it's a part of the fixtures
  end

  def when_i_run_the_import_command
    capture_output do
      Dry::CLI.new(MavisCLI).call(
        arguments: %w[
          gp-practices
          import
          -f
          spec/fixtures/files/nhs-gp-practices.zip
        ]
      )
    end
  end

  def then_gp_practices_are_imported_correctly
    expect(Location.count).to eq(4)
    expect(Location.find_by(ods_code: "A81001").name).to eq(
      "THE DENSHAM SURGERY"
    )
    expect(Location.find_by(ods_code: "A81002").name).to eq(
      "QUEENS PARK MEDICAL CENTRE"
    )
    expect(Location.find_by(ods_code: "A81003").name).to eq(
      "VICTORIA MEDICAL PRACTICE"
    )
    expect(Location.find_by(ods_code: "A81004").name).to eq(
      "ACKLAM MEDICAL CENTRE"
    )
  end
end
