# frozen_string_literal: true

describe "HPV vaccination" do
  before { Flipper.enable(:release_1b) }
  after { Flipper.disable(:release_1b) }

  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "cannot be recorded by an admin" do
    given_i_am_signed_in_as_an_admin
    when_i_go_to_a_patient_that_is_ready_to_vaccinate
    then_i_cannot_record_that_the_patient_has_been_vaccinated
  end

  def given_i_am_signed_in_as_an_admin
    programme = create(:programme, :hpv_all_vaccines)
    organisation =
      create(:organisation, :with_one_admin, programmes: [programme])
    location = create(:school)
    @session = create(:session, organisation:, programme:, location:)
    @patient =
      create(:patient, :consent_given_triage_not_needed, session: @session)

    sign_in organisation.users.first, role: :admin_staff
    visit "/"
    expect(page).to have_content(
      "#{organisation.users.first.full_name} (Administrator)"
    )
  end

  def when_i_go_to_a_patient_that_is_ready_to_vaccinate
    visit session_triage_path(@session)
    click_link "No triage needed"
    click_link @patient.full_name
  end

  def then_i_cannot_record_that_the_patient_has_been_vaccinated
    expect(page).not_to have_content("Did they get the HPV vaccine?")
  end
end
