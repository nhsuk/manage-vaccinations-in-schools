# frozen_string_literal: true

describe "User authorisation" do
  scenario "Users are unable to access other organisations' pages" do
    given_an_hpv_programme_is_underway_with_two_organisations
    when_i_sign_in_as_a_nurse_from_one_organisation
    and_i_go_to_the_consent_page
    then_i_should_only_see_my_patients

    when_i_go_to_the_session_page_of_another_organisation
    then_i_should_see_page_not_found

    when_i_go_to_the_consent_page_of_another_organisation
    then_i_should_see_page_not_found

    when_i_go_to_the_patient_page_of_another_organisation
    then_i_should_see_page_not_found

    when_i_go_to_the_sessions_page_filtered_by_programme
    then_i_should_only_see_my_sessions
  end

  def given_an_hpv_programme_is_underway_with_two_organisations
    @programme = create(:programme, :hpv)

    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
    @other_organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])

    location =
      create(:school, name: "Pilot School", organisation: @organisation)
    other_location =
      create(:school, name: "Other School", organisation: @other_organisation)
    @session =
      create(
        :session,
        :scheduled,
        organisation: @organisation,
        programmes: [@programme],
        location:
      )
    @other_session =
      create(
        :session,
        :scheduled,
        organisation: @other_organisation,
        programmes: [@programme],
        location: other_location
      )
    @child = create(:patient, session: @session)
    @other_child = create(:patient, session: @other_session)
  end

  def when_i_sign_in_as_a_nurse_from_one_organisation
    sign_in @organisation.users.first
  end

  def and_i_go_to_the_consent_page
    visit "/dashboard"
    click_on "Programmes", match: :first
    click_on "HPV"
    within ".app-secondary-navigation" do
      click_on "Sessions"
    end
    click_on "Pilot School"
    click_on "Consent"
  end

  def then_i_should_only_see_my_patients
    expect(page).to have_content(@child.full_name)
    expect(page).not_to have_content(@other_child.full_name)
  end

  def when_i_go_to_the_consent_page_of_another_organisation
    visit "/sessions/#{@other_session.id}/consent"
  end

  def then_i_should_see_page_not_found
    expect(page).to have_content("Page not found")
  end

  def when_i_go_to_the_session_page_of_another_organisation
    visit "/sessions/#{@other_session.id}"
  end

  def when_i_go_to_the_consent_page_of_another_organisation
    visit "/sessions/#{@other_session.id}/consent"
  end

  def when_i_go_to_the_patient_page_of_another_organisation
    visit "/patients/#{@other_session.id}/consent/given/patients/#{@other_child.id}"
  end

  def when_i_go_to_the_sessions_page_filtered_by_programme
    visit "/programmes/#{@programme.type}/#{Date.current.academic_year}/sessions"
  end

  def then_i_should_only_see_my_sessions
    expect(page).to have_content(@session.location.name)
    expect(page).not_to have_content(@other_session.location.name)
  end
end
