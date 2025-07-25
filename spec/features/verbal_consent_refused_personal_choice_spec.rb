# frozen_string_literal: true

describe "Verbal consent" do
  scenario "Refused personal choice (no notes)" do
    given_i_am_signed_in

    when_i_record_the_consent_refusal_and_reason

    then_an_email_is_sent_to_the_parent_confirming_the_refusal
    and_a_text_is_sent_to_the_parent_confirming_the_refusal
    and_the_patients_status_is_consent_refused
    and_i_can_see_the_consent_response_details
  end

  def given_i_am_signed_in
    programmes = [create(:programme, :hpv)]
    organisation = create(:organisation, :with_one_nurse, programmes:)
    @session = create(:session, organisation:, programmes:)

    @parent = create(:parent)
    @patient = create(:patient, session: @session, parents: [@parent])

    sign_in organisation.users.first
  end

  def when_i_record_the_consent_refusal_and_reason
    visit session_consent_path(@session)
    click_link @patient.full_name
    click_button "Record a new consent response"

    # Who are you trying to get consent from?
    choose @parent.full_name
    click_button "Continue"

    # Details for parent or guardian: leave prepopulated details
    click_button "Continue"

    # How was the response given?
    choose "By phone"
    click_button "Continue"

    # Do they agree?
    choose "No, they do not agree"
    click_button "Continue"

    # Reason
    choose "Personal choice"
    click_button "Continue"

    # No notes are asked for

    # Confirm
    expect(page).to have_content(["Decision", "Consent refused"].join)
    expect(page).to have_content(["Name", @parent.full_name].join)
    click_button "Confirm"

    expect(page).to have_content("Consent recorded for #{@patient.full_name}")
  end

  def and_the_patients_status_is_consent_refused
    click_link @patient.full_name, match: :first

    relation = @patient.parent_relationships.first.label
    expect(page).to have_content("Consent refused")
    expect(page).to have_content("#{relation} refused to give consent.")
  end

  def and_i_can_see_the_consent_response_details
    parent = @patient.parents.first
    click_link parent.full_name

    expect(page).to have_content(["Date", Time.zone.today.to_fs(:long)].join)
    expect(page).to have_content(["Decision", "Consent refused"].join)
    expect(page).to have_content(["Method", "By phone"].join)
    expect(page).to have_content(["Reason for refusal", "Personal choice"].join)
    expect(page).not_to have_content("Notes")

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

    expect(page).not_to have_content("Answers to health questions")
  end

  def then_an_email_is_sent_to_the_parent_confirming_the_refusal
    expect_email_to @patient.parents.first.email, :consent_confirmation_refused
  end

  def and_a_text_is_sent_to_the_parent_confirming_the_refusal
    expect_sms_to @patient.parents.first.phone, :consent_confirmation_refused
  end
end
