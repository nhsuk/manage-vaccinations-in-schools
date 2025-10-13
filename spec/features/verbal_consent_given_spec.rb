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
    and_i_can_see_the_consent_response_details(number_of_health_questions: 4)
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

  scenario "Given MMR" do
    given_an_mmr_programme_is_underway
    and_i_am_signed_in

    when_i_record_that_verbal_consent_was_given_with_gelatine
    then_i_see_the_check_and_confirm_page

    when_i_confirm_the_consent_response
    then_an_email_is_sent_to_the_parent_confirming_their_consent
    and_a_text_is_sent_to_the_parent_confirming_their_consent
    and_i_can_see_the_consent_response_details(number_of_health_questions: 3)
  end

  scenario "Given MMR without gelatine" do
    given_an_mmr_programme_is_underway
    and_i_am_signed_in

    when_i_record_that_verbal_consent_was_given_without_gelatine
    then_i_see_the_check_and_confirm_page

    when_i_confirm_the_consent_response
    then_an_email_is_sent_to_the_parent_confirming_their_consent
    and_a_text_is_sent_to_the_parent_confirming_their_consent
    and_i_can_see_the_consent_response_details(number_of_health_questions: 3)
  end

  def given_an_hpv_programme_is_underway
    create_programme(:hpv)
  end

  def given_a_flu_programme_is_underway
    create_programme(:flu)
  end

  def given_an_mmr_programme_is_underway
    create_programme(:mmr)
  end

  def and_i_am_signed_in
    sign_in @team.users.first
  end

  def create_programme(programme_type)
    @programme = create(:programme, programme_type)
    programmes = [@programme]
    @team = create(:team, :with_one_nurse, programmes:)
    @session = create(:session, team: @team, programmes:)

    @parent = create(:parent)
    @patient = create(:patient, session: @session, parents: [@parent])

    StatusUpdater.call
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
      number_of_health_questions: 4
    )
  end

  def when_i_record_that_verbal_nasal_consent_was_given
    record_that_verbal_consent_was_given(
      consent_option: "Yes, for the nasal spray",
      number_of_health_questions: 9
    )
  end

  def when_i_record_that_verbal_nasal_and_injection_consent_was_given
    record_that_verbal_consent_was_given(
      consent_option: "Yes, for the nasal spray",
      number_of_health_questions: 10,
      injective_alternative: true
    )
  end

  def when_i_record_that_verbal_consent_was_given_with_gelatine
    record_that_verbal_consent_was_given(
      consent_option: "Yes, they agree",
      number_of_health_questions: 3,
      without_gelatine: false
    )
  end

  def when_i_record_that_verbal_consent_was_given_without_gelatine
    record_that_verbal_consent_was_given(
      consent_option: "Yes, they agree",
      number_of_health_questions: 3,
      without_gelatine: true
    )
  end

  def record_that_verbal_consent_was_given(
    consent_option:,
    number_of_health_questions:,
    injective_alternative: nil,
    without_gelatine: nil
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
    unless without_gelatine.nil?
      if without_gelatine
        choose "Yes, they want their child to have a vaccine that does not contain gelatine"
      else
        choose "Their child can have either type of vaccine"
      end
    end
    click_button "Continue"

    number_of_health_questions.times do |index|
      find_all(".nhsuk-fieldset")[index].choose "No"
    end

    click_button "Continue"
  end

  def then_i_see_the_check_and_confirm_page
    expect(page).to have_content("Check and confirm answers")
    expect(page).to have_content(["Method", "By phone"].join)
    expect(page).not_to have_content(
      "Confirmation of vaccination sent to parent"
    )
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

  def and_i_can_see_the_consent_response_details(number_of_health_questions:)
    click_link @patient.full_name, match: :first
    click_link @parent.full_name

    expect(page).to have_content("Consent response from #{@parent.full_name}")
    expect(page).to have_content(["Date", Date.current.to_fs(:long)].join)
    expect(page).to have_content(["Response", "Consent given"].join)
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
      count: number_of_health_questions
    )
  end

  def then_an_email_is_sent_to_the_parent_confirming_their_consent
    expect_email_to(@parent.email, :consent_confirmation_given)
  end

  def and_a_text_is_sent_to_the_parent_confirming_their_consent
    expect_sms_to(@parent.phone, :consent_confirmation_given)
  end
end
