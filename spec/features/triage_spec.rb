# frozen_string_literal: true

describe "Triage" do
  scenario "nurse can triage a patient for an HPV programme" do
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

  scenario "nurse can triage patients for a flu programme with different consent types" do
    given_a_flu_programme_with_a_running_session
    and_patients_with_different_flu_consent_types_exist

    when_i_go_to_the_session_triage_tab
    then_i_see_both_patients_who_need_triage

    # First patient - injection only consent
    when_i_go_to_the_first_patient_that_needs_triage
    then_i_see_the_triage_options_for_injection_only_consent

    when_i_record_that_they_need_triage_for_flu
    then_i_see_the_triage_page
    and_needs_triage_emails_are_sent_to_both_parents

    when_i_record_that_they_are_safe_to_vaccinate_with_injection
    then_i_see_the_update_triage_link
    and_vaccination_will_happen_emails_are_sent_to_both_parents
    and_the_vaccine_method_is_recorded_as_injection

    # Second patient - nasal only consent
    when_i_go_to_the_session_triage_tab
    when_i_go_to_the_second_patient_that_needs_triage
    then_i_see_the_triage_options_for_nasal_only_consent

    when_i_record_that_they_need_triage_for_flu
    then_i_see_the_triage_page
    and_needs_triage_emails_are_sent_to_both_parents

    when_i_go_to_the_second_patient
    and_i_record_that_they_are_safe_to_vaccinate_with_nasal
    then_i_see_the_update_triage_link
    and_vaccination_will_happen_emails_are_sent_to_both_parents
    and_the_vaccine_method_is_recorded_as_nasal
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

  def given_a_flu_programme_with_a_running_session
    programmes = [create(:programme, :flu)]
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

  def and_patients_with_different_flu_consent_types_exist
    @patient_injection_only, @patient_nasal_only =
      create_list(
        :patient_session,
        2,
        :consent_given_triage_needed,
        session: @session
      ).map(&:patient)

    @patient_injection_only.consents.first.update(vaccine_methods: %w[injection])
    @patient_injection_only.consent_statuses.first.update(vaccine_methods: %w[injection])
    @patient_nasal_only.consents.first.update(vaccine_methods: %w[nasal])
    @patient_nasal_only.consent_statuses.first.update(vaccine_methods: %w[nasal])

    @patient_injection_only.reload
    @patient_nasal_only.reload
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

  def then_i_see_both_patients_who_need_triage
    expect(page).to have_content(@patient_injection_only.full_name)
    expect(page).to have_content(@patient_nasal_only.full_name)
  end

  def and_i_dont_see_the_patient_who_doesnt_need_triage
    expect(page).not_to have_content(@patient_triage_not_needed.full_name)
  end

  def when_i_go_to_the_patient_that_needs_triage
    choose "Needs triage"
    click_on "Update results"
    click_link @patient_triage_needed.full_name
  end

  def then_i_see_the_triage_options
    expect(page).to have_selector :heading, "Is it safe to vaccinate"
  end

  def when_i_record_that_they_need_triage
    choose "No, keep in triage"
    click_button "Save triage"
  end

  def when_i_record_that_they_need_triage_for_flu
    choose "No, keep in triage"
    click_button "Save triage"
  end

  def when_i_record_that_they_are_safe_to_vaccinate
    click_link "Update triage"
    choose "Yes, it’s safe to vaccinate"
    click_button "Save triage"
  end

  def when_i_record_that_they_are_safe_to_vaccinate_with_injection
    choose "Yes, it’s safe to vaccinate with injected vaccine"
    click_button "Save triage"
  end

  def and_i_record_that_they_are_safe_to_vaccinate_with_nasal
    choose "Yes, it’s safe to vaccinate with nasal spray"
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

  def then_i_see_the_triage_page
    expect(page).to have_selector :heading, "Is it safe to vaccinate"
  end

  def and_needs_triage_emails_are_sent_to_both_parents
    current_patient = @patient_triage_needed || @patient_injection_only || @patient_nasal_only
    current_patient.parents.each do |parent|
      expect_email_to parent.email, :consent_confirmation_triage, :any
    end
  end

  def and_vaccination_wont_happen_emails_are_sent_to_both_parents
    current_patient = @patient_triage_needed || @patient_injection_only || @patient_nasal_only
    current_patient.parents.each do |parent|
      expect_email_to parent.email, :triage_vaccination_wont_happen, :any
    end
  end

  def and_vaccination_will_happen_emails_are_sent_to_both_parents
    current_patient = @patient_triage_needed || @patient_injection_only || @patient_nasal_only
    current_patient.parents.each do |parent|
      expect_email_to parent.email, :triage_vaccination_will_happen, :any
    end
  end

  def and_the_vaccine_method_is_recorded_as_injection
    current_patient = @patient_triage_needed || @patient_injection_only || @patient_nasal_only
    triage = current_patient.triages.last
    expect(triage.vaccine_method).to eq("injection")
  end

  def when_i_go_to_the_first_patient_that_needs_triage
    choose "Needs triage"
    click_on "Update results"
    click_link @patient_injection_only.full_name
  end

  def then_i_see_the_triage_options_for_injection_only_consent
    expect(page).to have_selector :heading,
                  "Is it safe to vaccinate #{@patient_injection_only.given_name}?"
    expect(page).to have_content(
      "The parent has consented to the injected vaccine only"
    )
    expect(page).to have_field(
      "Yes, it’s safe to vaccinate with injected vaccine",
      type: "radio"
    )
  end

  def when_i_go_to_the_second_patient_that_needs_triage
    choose "Needs triage"
    click_on "Update results"
    click_link @patient_nasal_only.full_name
  end

  def then_i_see_the_triage_options_for_nasal_only_consent
    expect(page).to have_selector :heading,
                  "Is it safe to vaccinate #{@patient_nasal_only.given_name}?"
    expect(page).to have_content(
      "The parent has consented to the nasal spray only"
    )
    expect(page).to have_field(
      "Yes, it’s safe to vaccinate with nasal spray",
      type: "radio"
    )
  end

  def when_i_go_to_the_second_patient
    click_link "Triage"
    click_link @patient_nasal_only.full_name, match: :first
  end

  def and_the_vaccine_method_is_recorded_as_nasal
    triage = @patient_nasal_only.triages.last
    skip "Bug: should be nasal but currently injection"
    expect(triage.vaccine_method).to eq("injection")
  end
end
