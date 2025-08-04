# frozen_string_literal: true

describe "Verbal consent" do
  scenario "Given HPV" do
    given_an_hpv_programme_is_underway
    and_i_am_signed_in

    when_i_record_that_verbal_consent_was_given
    then_i_see_the_check_and_confirm_page

    when_i_confirm_the_consent_response
    then_an_email_is_sent_to_the_parent_confirming_their_consent
    and_a_text_is_sent_to_the_parent_confirming_their_consent
    and_the_patients_status_is_safe_to_vaccinate
    and_i_can_see_the_consent_response_details
  end

  scenario "Given flu injection" do
    given_a_flu_programme_is_underway
    and_i_am_signed_in

    when_i_record_that_verbal_injection_consent_was_given
    then_i_see_the_check_and_confirm_page
    and_i_see_the_flu_injection_consent_given

    when_i_confirm_the_consent_response
    then_an_email_is_sent_to_the_parent_confirming_their_consent
    and_a_text_is_sent_to_the_parent_confirming_their_consent
  end

  scenario "Given flu nasal spray" do
    given_a_flu_programme_is_underway
    and_i_am_signed_in

    when_i_record_that_verbal_nasal_consent_was_given
    then_i_see_the_check_and_confirm_page
    and_i_see_the_flu_nasal_consent_given

    when_i_confirm_the_consent_response
    then_an_email_is_sent_to_the_parent_confirming_their_consent
    and_a_text_is_sent_to_the_parent_confirming_their_consent
    and_the_patients_status_is_safe_to_vaccinate_with_nasal_spray
  end

  scenario "Given flu nasal spray and injection" do
    given_a_flu_programme_is_underway
    and_i_am_signed_in

    when_i_record_that_verbal_nasal_and_injection_consent_was_given
    then_i_see_the_check_and_confirm_page
    and_i_see_the_flu_nasal_and_injection_consent_given

    when_i_confirm_the_consent_response
    then_an_email_is_sent_to_the_parent_confirming_their_consent
    and_a_text_is_sent_to_the_parent_confirming_their_consent
  end

  def given_an_hpv_programme_is_underway
    create_programme(:hpv)
  end

  def given_a_flu_programme_is_underway
    create_programme(:flu)
  end

  def and_i_am_signed_in
    sign_in @organisation.users.first
  end

  def create_programme(programme_type)
    @programme = create(:programme, programme_type)
    programmes = [@programme]
    @organisation = create(:organisation, :with_one_nurse, programmes:)
    @session = create(:session, organisation: @organisation, programmes:)

    @parent = create(:parent)
    @patient = create(:patient, session: @session, parents: [@parent])
  end

  def when_i_record_that_verbal_consent_was_given
    record_that_verbal_consent_was_given(
      consent_option: "Yes, they agree",
      number_of_health_questions: 4
    )
  end

  def when_i_record_that_verbal_injection_consent_was_given
    record_that_verbal_consent_was_given(
      consent_option: "Yes, for the injected vaccine only",
      number_of_health_questions: 4,
      triage_option: "Yes, it’s safe to vaccinate with injected vaccine"
    )
  end

  def when_i_record_that_verbal_nasal_consent_was_given
    record_that_verbal_consent_was_given(
      consent_option: "Yes, for the nasal spray",
      number_of_health_questions: 9,
      triage_option: "Yes, it’s safe to vaccinate with nasal spray"
    )
  end

  def when_i_record_that_verbal_nasal_and_injection_consent_was_given
    record_that_verbal_consent_was_given(
      consent_option: "Yes, for the nasal spray",
      number_of_health_questions: 10,
      triage_option: "Yes, it’s safe to vaccinate with nasal spray",
      injective_alternative: true
    )
  end

  def record_that_verbal_consent_was_given(
    consent_option:,
    number_of_health_questions:,
    triage_option: "Yes, it’s safe to vaccinate",
    injective_alternative: false
  )
    visit session_consent_path(@session)
    click_link @patient.full_name
    click_button "Record a new consent response"

    # Who are you trying to get consent from?
    click_button "Continue"
    expect(page).to have_content(
      "Choose who you are trying to get consent from"
    )

    choose "#{@parent.full_name} (#{@patient.parent_relationships.first.label})"
    click_button "Continue"

    # Details for parent or guardian
    expect(page).to have_content(
      "Details for #{@parent.full_name} (#{@patient.parent_relationships.first.label})"
    )
    # don't change any details
    click_button "Continue"

    # How was the response given?
    choose "By phone"
    click_button "Continue"

    # Do they agree?
    choose consent_option
    if consent_option.include?("nasal")
      choose injective_alternative ? "Yes" : "No"
    end
    click_button "Continue"

    number_of_health_questions.times do |index|
      find_all(".nhsuk-fieldset")[index].choose "No"
    end

    click_button "Continue"

    choose triage_option
    click_button "Continue"
  end

  def then_i_see_the_check_and_confirm_page
    expect(page).to have_content("Check and confirm answers")
    expect(page).to have_content(["Method", "By phone"].join)
  end

  def and_i_see_the_flu_injection_consent_given
    expect(page).to have_content("Consent givenInjection")
  end

  def and_i_see_the_flu_nasal_consent_given
    expect(page).to have_content("Consent givenNasal spray")
    expect(page).to have_content("Consent also given for injected vaccine?No")
  end

  def and_i_see_the_flu_nasal_and_injection_consent_given
    expect(page).to have_content("Consent givenNasal spray")
    expect(page).to have_content("Consent also given for injected vaccine?Yes")
  end

  def when_i_confirm_the_consent_response
    click_button "Confirm"
    expect(page).to have_content("Consent recorded for #{@patient.full_name}")
  end

  def and_the_patients_status_is_safe_to_vaccinate
    click_link @patient.full_name, match: :first
    expect(page).to have_content("Safe to vaccinate")
  end

  def and_the_patients_status_is_safe_to_vaccinate_with_nasal_spray
    click_link @patient.full_name, match: :first
    expect(page).to have_content("Safe to vaccinate with nasal spray")
  end

  def and_i_can_see_the_consent_response_details
    click_link @parent.full_name

    expect(page).to have_content("Consent response from #{@parent.full_name}")
    expect(page).to have_content(["Date", Date.current.to_fs(:long)].join)
    expect(page).to have_content(["Decision", "Consent given"].join)
    expect(page).to have_content(["Method", "By phone"].join)

    expect(page).to have_content(["Full name", @patient.full_name].join)
    expect(page).to have_content(
      ["Date of birth", @patient.date_of_birth.to_fs(:long)].join
    )
    expect(page).to have_content(["School", @patient.school.name].join)

    expect(page).to have_content(["Name", @parent.full_name].join)
    expect(page).to have_content(
      ["Relationship", @patient.parent_relationships.first.label].join
    )
    expect(page).to have_content(["Email address", @parent.email].join("\n"))
    expect(page).to have_content(["Phone number", @parent.phone].join("\n"))

    expect(page).to have_content("Answers to health questions")
    expect(page).to have_content(
      "#{@patient.parent_relationships.first.label} responded: No",
      count: 4
    )
  end

  def then_an_email_is_sent_to_the_parent_confirming_their_consent
    expect_email_to(@parent.email, :consent_confirmation_given)
  end

  def and_a_text_is_sent_to_the_parent_confirming_their_consent
    expect_sms_to(@parent.phone, :consent_confirmation_given)
  end
end
