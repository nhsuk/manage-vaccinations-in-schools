# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis generate vaccination_records" do
  it "generates consents" do
    given_an_organisation_exists
    and_there_is_a_patient_in_a_session
    when_i_run_the_generate_vaccination_records_command
    then_vaccination_administered_records_are_created
  end

  def given_an_organisation_exists
    @programme = create(:programme, type: "hpv")
    @organisation = create(:organisation, programmes: [@programme])
  end

  def and_there_is_a_patient_in_a_session
    team = create(:team, organisation: @organisation)
    location = create(:generic_clinic, team:)
    @session =
      create(
        :session,
        organisation: @organisation,
        programmes: [@programme],
        location:
      )
    parent = create(:parent)
    create(
      :patient,
      :consent_given_triage_not_needed,
      organisation: @organisation,
      session: @session,
      programmes: [@programme],
      parents: [parent]
    )
  end

  def when_i_run_the_generate_vaccination_records_command
    @vaccination_records_count_before = @organisation.vaccination_records.count

    Dry::CLI.new(MavisCLI).call(
      arguments: [
        "generate",
        "vaccination-records",
        "-o",
        @organisation.ods_code.to_s,
        "-p",
        @programme.type,
        "-s",
        @session.id.to_s,
        "-A",
        "1"
      ]
    )
  end

  def then_vaccination_administered_records_are_created
    expect(
      @organisation.reload.vaccination_records.count
    ).to eq @vaccination_records_count_before + 1

    expect(
      @organisation
        .reload
        .patients
        .has_vaccination_status(:vaccinated, programme: @programme)
        .count
    ).to eq 1
  end
end
