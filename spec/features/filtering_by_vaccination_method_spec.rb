# frozen_string_literal: true

describe "Filtering" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "By vaccination method" do
    given_a_session_exists_with_programmes(%i[flu hpv])
    and_patients_are_in_the_flu_hpv_session

    when_i_visit_the_record_vaccinations_tab
    then_the_any_vaccination_method_filter_is_selected
    then_i_see_patients(@all_flu_hpv_patients)

    when_i_filter_on("Nasal")
    then_i_see_patients(@nasal_eligible_patients)

    when_i_filter_on("Injection")
    then_i_see_patients(@injection_eligible_patients)
  end

  scenario "With no flu programme in session" do
    given_a_session_exists_with_programmes(%i[td_ipv menacwy])
    and_patients_are_in_the_doubles_session

    when_i_visit_the_record_vaccinations_tab
    then_i_see_patients(@all_doubles_patients)
    and_i_dont_see_vaccination_method_filter_radios
  end

  scenario "By programme and vaccination method" do
    given_a_session_exists_with_programmes(%i[flu hpv])
    and_patients_are_in_the_flu_hpv_session

    when_i_visit_the_record_vaccinations_tab

    when_i_filter_on_programme_and_method("Flu", "Nasal")
    then_i_see_patients(@flu_nasal_patients)

    when_i_filter_on_programme_and_method("HPV", "Injection")
    then_i_see_patients(@hpv_injection_patients)

    when_i_filter_on_programme_and_method("Flu", "Injection")
    then_i_see_patients(@flu_injection_patients)

    when_i_filter_on_programme_and_method("HPV", "Nasal")
    then_i_see_no_patients
  end

  scenario "With patient consented for nasal and injection" do
    given_a_session_exists_with_programmes(%i[flu])
    and_patient_with_consent_for_nasal_and_injection_is_in_the_session

    when_i_visit_the_record_vaccinations_tab

    when_i_filter_on("Nasal")
    then_i_see_patients([@patient_consented_for_nasal_and_injection])

    when_i_filter_on("Injection")
    then_i_see_no_patients
  end

  private

  def given_a_session_exists_with_programmes(programme_types)
    programmes = programme_types.map { |type| create(:programme, type) }
    organisation = create(:organisation, programmes:)
    @nurse = create(:nurse, organisation:)
    @session = create(:session, organisation:, programmes:)
  end

  def and_patients_are_in_the_flu_hpv_session
    @patient_consented_for_flu_nasal =
      create_patient(
        :consent_given_nasal_only_triage_not_needed,
        3,
        [@session.programmes.first]
      )

    @patient_consented_for_flu_injection =
      create_patient(
        :consent_given_triage_not_needed,
        3,
        [@session.programmes.first]
      )

    @patient_consented_for_flu_both_triaged_nasal =
      create_patient(
        :consent_given_injection_and_nasal_triage_safe_to_vaccinate_nasal,
        5,
        [@session.programmes.first]
      )
    @patient_consented_for_hpv_and_flu_injection =
      create_patient(:consent_given_triage_not_needed, 8, @session.programmes)

    @all_flu_hpv_patients = [
      @patient_consented_for_flu_nasal,
      @patient_consented_for_flu_injection,
      @patient_consented_for_flu_both_triaged_nasal,
      @patient_consented_for_hpv_and_flu_injection
    ]
    @nasal_eligible_patients = [
      @patient_consented_for_flu_nasal,
      @patient_consented_for_flu_both_triaged_nasal
    ]
    @injection_eligible_patients = [
      @patient_consented_for_hpv_and_flu_injection,
      @patient_consented_for_flu_injection
    ]
    @flu_nasal_patients = [
      @patient_consented_for_flu_nasal,
      @patient_consented_for_flu_both_triaged_nasal
    ]
    @hpv_injection_patients = [@patient_consented_for_hpv_and_flu_injection]
    @flu_injection_patients = [
      @patient_consented_for_flu_injection,
      @patient_consented_for_hpv_and_flu_injection
    ]
  end

  def and_patients_are_in_the_doubles_session
    @patient_consented_for_doubles =
      create_patient(:consent_given_triage_not_needed, 9, @session.programmes)
    @patient_consented_for_doubles_triaged_safe_to_vaccinate =
      create_patient(
        :consent_given_triage_safe_to_vaccinate,
        10,
        @session.programmes
      )

    @all_doubles_patients = [
      @patient_consented_for_doubles,
      @patient_consented_for_doubles_triaged_safe_to_vaccinate
    ]
  end

  def and_patient_with_consent_for_nasal_and_injection_is_in_the_session
    @patient_consented_for_nasal_and_injection =
      create_patient(
        :consent_given_nasal_or_injection_triage_not_needed,
        3,
        @session.programmes
      )
  end

  def create_patient(trait, year_group, programmes)
    create(
      :patient,
      trait,
      :in_attendance,
      year_group: year_group,
      session: @session,
      programmes:
    )
  end

  def when_i_visit_the_record_vaccinations_tab
    sign_in @nurse
    visit session_record_path(@session)
  end

  def when_i_filter_on(method)
    choose method
    click_on "Update results"
  end

  def when_i_filter_on_programme_and_method(programme, method)
    uncheck "Flu" if page.has_checked_field?("Flu")
    uncheck "HPV" if page.has_checked_field?("HPV")

    check programme
    choose method
    click_on "Update results"
  end

  def then_i_see_patients(patients)
    patients.each { |patient| expect(page).to have_content(patient.full_name) }

    all_test_patients = [
      @patient_consented_for_flu_nasal,
      @patient_consented_for_flu_injection,
      @patient_consented_for_flu_both_triaged_nasal,
      @patient_consented_for_hpv_and_flu_injection,
      @patient_consented_for_doubles,
      @patient_consented_for_doubles_triaged_safe_to_vaccinate,
      @patient_consented_for_nasal_and_injection
    ].compact

    (all_test_patients - patients).each do |patient|
      expect(page).not_to have_content(patient.full_name)
    end
  end

  def then_i_see_no_patients
    expect(page).to have_content("No children matching search criteria found")
  end

  def and_i_dont_see_vaccination_method_filter_radios
    expect(page).not_to have_field("Nasal", type: "radio")
    expect(page).not_to have_field("Injection", type: "radio")
  end

  def then_the_any_vaccination_method_filter_is_selected
    expect(page).to have_checked_field("Any")
  end
end
