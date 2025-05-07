# frozen_string_literal: true

describe "Filter state persistence" do
  scenario "filters maintain state across navigation" do
    given_i_am_signed_in

    when_i_visit_the_consent_page
    and_i_apply_consent_filters
    then_the_consent_filters_are_applied

    when_i_navigate_to_another_page
    and_i_return_to_the_consent_page
    then_the_consent_filters_are_still_applied

    when_i_clear_the_consent_filters
    then_i_should_see_no_applied_filters

    when_i_visit_the_triage_page
    and_i_apply_triage_filters
    then_the_triage_filters_are_applied

    when_i_navigate_to_another_page
    and_i_return_to_the_triage_page
    then_the_triage_filters_are_still_applied

    when_i_visit_the_consent_page
    then_i_should_see_no_applied_filters
  end

  def given_i_am_signed_in
    @programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
    @session =
      create(:session, organisation: @organisation, programmes: [@programme])

    sign_in @organisation.users.first
  end

  def when_i_visit_the_consent_page
    visit session_consent_path(@session)
  end

  def and_i_apply_consent_filters
    check "Consent given"
    click_on "Update results"
  end

  def then_the_consent_filters_are_applied
    expect(page).to have_checked_field("Consent given")
  end

  def then_the_consent_filters_are_still_applied
    expect(page).to have_checked_field("Consent given")
  end

  def when_i_clear_the_consent_filters
    click_on "Clear filters"
  end

  def when_i_navigate_to_another_page
    visit root_path
  end

  def and_i_return_to_the_consent_page
    visit session_consent_path(@session)
  end

  def when_i_visit_the_triage_page
    visit session_triage_path(@session)
  end

  def and_i_apply_triage_filters
    choose "Safe to vaccinate"
    click_on "Update results"
  end

  def then_the_triage_filters_are_applied
    expect(page).to have_checked_field("Safe to vaccinate")
  end

  def and_i_return_to_the_triage_page
    visit session_triage_path(@session)
  end

  def then_the_triage_filters_are_still_applied
    expect(page).to have_checked_field("Safe to vaccinate")
  end

  def when_i_clear_the_triage_filters
    click_on "Clear filters"
  end

  def then_i_should_see_no_applied_filters
    expect(page).not_to have_checked_field
  end
end
