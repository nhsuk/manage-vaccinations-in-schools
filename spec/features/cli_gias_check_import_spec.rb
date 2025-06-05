# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis gias check_import" do
  it "counts the number of locations closed that have future sessions" do
    given_an_organisation_exists
    and_there_are_locations_with_future_sessions
    when_i_run_the_check_import_command
    then_i_should_see_the_correct_counts
  end

  def given_an_organisation_exists
    @organisation = create(:organisation, ods_code: "A9A5A")
    @programme = create(:programme, :hpv)
  end

  def and_there_are_locations_with_future_sessions
    @location_with_future_session =
      create(:school, name: "The Aldgate School", urn: "100000")
    @session_with_future_dates =
      create(
        :session,
        location: @location_with_future_session,
        dates: [Date.tomorrow],
        programmes: [@programme]
      )

    @location2_with_future_session =
      create(:school, name: "St Paul's Cathedral School", urn: "100002")
    @session_with_future_dates =
      create(
        :session,
        location: @location2_with_future_session,
        dates: [Date.tomorrow],
        programmes: [@programme]
      )

    @location_without_future_session =
      create(:school, name: "City of London School for Girls", urn: "100001")
    @session_without_future_dates =
      create(
        :session,
        location: @location_without_future_session,
        dates: [Date.yesterday],
        programmes: [@programme]
      )
  end

  def when_i_run_the_check_import_command
    # This will exit if the command is not found. We could mock out Kernel.exit
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: %w[
            gias
            check-import
            -i
            spec/fixtures/files/dfe-schools.zip
          ]
        )
      end
  end

  def then_i_should_see_the_correct_counts
    expect(@output).to eq <<~OUTPUT
                        New locations (total): 1
                     Closed locations (total): 1
      Proposed to be closed locations (total): 1

       Existing locations with future sessions: 2
                     That are closed in import: 1 (50.0%)
      That are proposed to be closed in import: 1 (50.0%)

      URNs of closed locations with future sessions:
        100000
    OUTPUT
  end
end
