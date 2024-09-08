# frozen_string_literal: true

describe "Parental consent for a backfilled session" do
  scenario "Consent form is shown as closed" do
    given_an_hpv_programme_is_underway_with_a_backfilled_session
    when_i_go_to_the_consent_form
    then_i_see_that_consent_is_closed
  end

  def given_an_hpv_programme_is_underway_with_a_backfilled_session
    @team = create(:team, :with_one_nurse)
    programme = create(:programme, :hpv, team: @team)
    location = create(:location, :school, name: "Pilot School")
    @session = create(:session, :in_past, :minimal, programme:, location:)
  end

  def when_i_go_to_the_consent_form
    visit start_session_parent_interface_consent_forms_path(@session)
  end

  def then_i_see_that_consent_is_closed
    expect(page).to have_content("The deadline for responding has passed")
  end
end
