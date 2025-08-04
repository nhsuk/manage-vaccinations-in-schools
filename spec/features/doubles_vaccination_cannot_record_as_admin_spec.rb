# frozen_string_literal: true

describe "MenACWY and Td/IPV vaccination" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "Cannot be recorded by an admin" do
    given_i_am_signed_in_as_an_admin
    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    then_i_cannot_record_that_the_patient_has_been_vaccinated
  end

  def given_i_am_signed_in_as_an_admin
    programmes = [create(:programme, :menacwy), create(:programme, :td_ipv)]
    team = create(:team, :with_one_admin, programmes:)

    location = create(:school, team:)

    @session = create(:session, team:, programmes:, location:)
    @patient =
      create(:patient, :consent_given_triage_not_needed, session: @session)

    create(
      :patient_session_registration_status,
      patient_session:
        @patient.patient_sessions.includes(session: :session_dates).first
    )

    create(
      :vaccination_record,
      patient: @patient,
      programme: programmes.first,
      session: @session
    )

    sign_in team.users.first, role: :admin_staff

    visit "/"

    expect(page).to have_content(
      "#{team.users.first.full_name} (Administrator)"
    )
  end

  def when_i_go_to_a_patient_that_is_ready_to_vaccinate
    visit session_register_path(@session)
    choose "Not registered yet"
    click_on "Update results"
    click_link @patient.full_name
  end

  def then_i_cannot_record_that_the_patient_has_been_vaccinated
    expect(page).not_to have_content("ready for their HPV vaccination?")
    expect(page).not_to have_content("You still need to record an outcome")
  end
end
