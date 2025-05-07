# frozen_string_literal: true

describe "Triage" do
  scenario "nurse can triage a patient" do
    given_a_programme_with_a_running_session
    and_a_patient_who_needs_triage_exists
    and_a_patient_who_doesnt_need_triage_exists

    when_i_go_to_the_session_triage_tab
    then_i_see_the_patient_who_needs_triage
    and_i_dont_see_the_patient_who_doesnt_need_triage

    when_i_go_to_the_patient_that_needs_triage
    then_i_see_the_triage_options

    when_i_save_the_triage_without_choosing_an_option
    then_i_see_a_validation_error

    when_i_record_that_they_need_triage
    then_i_see_the_triage_options
    and_needs_triage_emails_are_sent_to_both_parents

    when_i_do_not_vaccinate
    and_vaccination_wont_happen_emails_are_sent_to_both_parents

    when_i_record_that_they_are_safe_to_vaccinate
    then_i_see_the_update_triage_link
    and_vaccination_will_happen_emails_are_sent_to_both_parents
  end

  def given_a_programme_with_a_running_session
    programmes = [create(:programme, :hpv)]
    @organisation = create(:organisation, :with_one_nurse, programmes:)

    @batch =
      create(
        :batch,
        organisation: @organisation,
        vaccine: programmes.first.vaccines.first
      )

    @session = create(:session, organisation: @organisation, programmes:)
  end

  def and_a_patient_who_needs_triage_exists
    @patient_triage_needed =
      create(
        :patient_session,
        :consent_given_triage_needed,
        session: @session
      ).patient

    create(
      :consent,
      :given,
      :health_question_notes,
      :from_granddad,
      patient: @patient_triage_needed,
      programme: @session.programmes.first
    )

    @patient_triage_needed.reload # Make sure both consents are accessible
  end

  def and_a_patient_who_doesnt_need_triage_exists
    @patient_triage_not_needed =
      create(
        :patient_session,
        :consent_given_triage_not_needed,
        session: @session
      ).patient
  end

  def when_i_go_to_the_session_triage_tab
    sign_in @organisation.users.first
    visit session_triage_path(@session)
  end

  def then_i_see_the_patient_who_needs_triage
    expect(page).to have_content(@patient_triage_needed.full_name)
  end

  def and_i_dont_see_the_patient_who_doesnt_need_triage
    expect(page).not_to have_content(@patient_triage_not_needed.full_name)
  end

  def when_i_go_to_the_patient_that_needs_triage
    choose "Needs triage"
    click_on "Update results"
    click_link @patient_triage_needed.full_name
  end

  def when_i_go_to_the_patient
    click_link @patient_triage_needed.full_name, match: :first
  end

  def then_i_see_the_triage_options
    expect(page).to have_selector :heading, "Is it safe to vaccinate"
  end

  def when_i_record_that_they_need_triage
    choose "No, keep in triage"
    click_button "Save triage"
  end

  def when_i_record_that_they_are_safe_to_vaccinate
    click_link "Update triage"
    choose "Yes, it’s safe to vaccinate"
    click_button "Save triage"
  end

  def when_i_do_not_vaccinate
    choose "No, do not vaccinate"
    click_button "Save triage"
  end

  def when_i_save_the_triage_without_choosing_an_option
    click_button "Save triage"
  end

  def then_i_see_a_validation_error
    expect(page).to have_selector :heading, "There is a problem"
  end

  def then_i_see_the_update_triage_link
    expect(page).to have_link "Update triage"
  end

  def and_needs_triage_emails_are_sent_to_both_parents
    @patient_triage_needed.parents.each do |parent|
      expect_email_to parent.email, :consent_confirmation_triage, :any
    end
  end

  def and_vaccination_wont_happen_emails_are_sent_to_both_parents
    @patient_triage_needed.parents.each do |parent|
      expect_email_to parent.email, :triage_vaccination_wont_happen, :any
    end
  end

  def and_vaccination_will_happen_emails_are_sent_to_both_parents
    @patient_triage_needed.parents.each do |parent|
      expect_email_to parent.email, :triage_vaccination_will_happen, :any
    end
  end
end
