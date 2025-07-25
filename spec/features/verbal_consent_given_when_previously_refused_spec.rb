# frozen_string_literal: true

feature "Verbal consent" do
  scenario "Given when previously refused" do
    given_an_hpv_programme_is_underway
    and_a_parent_has_refused_consent_for_their_child
    and_i_am_logged_in_as_a_nurse

    when_i_record_the_consent_given_for_that_child_from_the_same_parent

    then_an_email_is_sent_to_the_parent_confirming_their_consent
    and_the_child_is_shown_as_having_consent_given
  end

  def given_an_hpv_programme_is_underway
    @programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
    location =
      create(:school, name: "Pilot School", organisation: @organisation)
    @session =
      create(
        :session,
        :scheduled,
        organisation: @organisation,
        programmes: [@programme],
        location:
      )
  end

  def and_a_parent_has_refused_consent_for_their_child
    @child =
      create(
        :patient_session,
        :consent_refused,
        programmes: [@programme],
        session: @session
      ).patient
  end

  def and_i_am_logged_in_as_a_nurse
    sign_in @organisation.users.first
  end

  def when_i_record_the_consent_given_for_that_child_from_the_same_parent
    @refusing_parent = @child.consents.first.parent

    visit "/dashboard"
    click_on "Programmes", match: :first
    click_on "HPV"
    within ".app-secondary-navigation" do
      click_on "Sessions"
    end
    click_on "Pilot School"
    click_on "Consent"
    check "Consent refused"
    click_on "Update results"
    click_on @child.full_name
    click_on "Record a new consent response"

    # contacting the same parent who refused
    choose @refusing_parent.full_name
    click_button "Continue"

    # Details for parent or guardian
    fill_in "Phone number", with: @refusing_parent.phone
    fill_in "Email address", with: @refusing_parent.email
    click_button "Continue"

    choose "By phone"
    click_button "Continue"

    choose "Yes, they agree"
    click_button "Continue"

    # Health questions
    find_all(".nhsuk-fieldset")[0].choose "No"
    find_all(".nhsuk-fieldset")[1].choose "No"
    find_all(".nhsuk-fieldset")[2].choose "No"
    find_all(".nhsuk-fieldset")[3].choose "No"
    click_button "Continue"

    choose "Yes, it’s safe to vaccinate"
    click_button "Continue"

    click_button "Confirm"

    expect(page).to have_alert(
      "Success",
      text: "Consent recorded for #{@child.full_name}"
    )
  end

  def then_an_email_is_sent_to_the_parent_confirming_their_consent
    expect_email_to(@refusing_parent.email, :consent_confirmation_given)
  end

  def and_a_text_is_sent_to_the_parent_confirming_their_consent
    expect_sms_to(@refusing_parent.phone, :consent_confirmation_given)
  end

  def and_the_child_is_shown_as_having_consent_given
    check "Consent given"
    click_on "Update results"

    expect(page).to have_content(@child.full_name)

    click_on @child.full_name
    expect(page).to have_content("Safe to vaccinate")
  end
end
