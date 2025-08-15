# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis gias import" do
  it "imports schools from a GIAS file" do
    given_a_gias_file_exists
    when_i_run_the_import_command
    then_schools_are_imported_correctly
  end

  def given_a_gias_file_exists
    # Nothing to do here, it's a part of the fixtures
  end

  def when_i_run_the_import_command
    capture_output do
      Dry::CLI.new(MavisCLI).call(
        arguments: %w[gias import -f spec/fixtures/files/dfe-schools.zip]
      )
    end
  end

  def then_schools_are_imported_correctly
    expect(Location.count).to eq 4
    expect(
      Location.find_by_urn_and_site("100000").name
    ).to eq "The Aldgate School"
    expect(Location.find_by_urn_and_site("100000").status).to eq "closed"
    expect(Location.find_by_urn_and_site("100001").status).to eq "closed"
    expect(Location.find_by_urn_and_site("100002").status).to eq "closing"
    expect(Location.find_by_urn_and_site("100003").status).to eq "open"
  end
end
