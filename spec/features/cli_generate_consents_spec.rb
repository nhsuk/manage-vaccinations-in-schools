# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis generate consents" do
  it "generates consents" do
    given_an_organisation_exists
    and_there_are_three_patients_in_a_session
    when_i_run_the_generate_consents_command
    then_consents_are_created_with_the_given_statuses
  end

  def given_an_organisation_exists
    @organisation = create(:organisation)
    @programme = create(:programme, type: "hpv")
  end

  def and_there_are_three_patients_in_a_session
    @session =
      create(:session, organisation: @organisation, programmes: [@programme])
    parent = create(:parent)
    create_list(
      :patient,
      3,
      organisation: @organisation,
      session: @session,
      programmes: [@programme],
      parents: [parent]
    )
  end

  def when_i_run_the_generate_consents_command
    @consent_count_before = @organisation.consents.count

    Dry::CLI.new(MavisCLI).call(
      arguments: [
        "generate",
        "consents",
        "-o",
        @organisation.ods_code.to_s,
        "-p",
        @programme.type,
        "-s",
        @session.id.to_s,
        "-g",
        "1",
        "-N",
        "1",
        "-r",
        "1"
      ]
    )
  end

  def then_consents_are_created_with_the_given_statuses
    expect(@organisation.consents.count).to eq @consent_count_before + 3

    expect(
      @organisation
        .patient_sessions
        .has_consent_status(:given, programme: @programme)
        .has_triage_status(:not_required, programme: @programme)
        .count
    ).to eq 1
  end
end
