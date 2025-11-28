# frozen_string_literal: true

describe "Filtering" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "By vaccine type" do
    given_a_session_exists_with_programmes(%w[flu hpv])
    and_patients_are_in_the_flu_hpv_session

    when_i_visit_the_record_vaccinations_tab
    and_i_see_all_the_patients_in_flu_hpv_session

    when_i_filter_on_nasal_spray_only
    then_i_see_only_the_patients_eligible_for_nasal_spray_only

    when_i_filter_on_nasal_spray_preferred
    then_i_see_only_the_patients_eligible_for_nasal_spray_preferred

    when_i_filter_on_injection_only
    then_i_see_only_the_patients_eligible_for_injection_only
  end

  scenario "With no flu programme in session" do
    given_a_session_exists_with_programmes(%w[td_ipv menacwy])
    and_patients_are_in_the_doubles_session

    when_i_visit_the_record_vaccinations_tab
    then_i_see_all_the_patients_in_doubles_session
    and_i_dont_see_vaccine_criteria_filter_radios
  end

  scenario "By programme and vaccine type" do
    given_a_session_exists_with_programmes(%w[flu hpv])
    and_patients_are_in_the_flu_hpv_session

    when_i_visit_the_record_vaccinations_tab
    and_i_filter_on_flu_and_nasal
    then_i_see_only_flu_patients_eligible_for_nasal

    when_i_filter_on_hpv_and_injection
    then_i_see_only_hpv_patients_eligible_for_injection

    when_i_filter_on_flu_and_injection
    then_i_see_only_flu_patients_eligible_for_injection

    when_i_filter_on_hpv_and_nasal
    then_i_see_no_patients
  end

  def given_a_session_exists_with_programmes(programme_types)
    programmes = programme_types.map { Programme.find(it) }
    team = create(:team, programmes:)
    @nurse = create(:nurse, team:)
    @session = create(:session, team:, programmes:)
  end

  def and_patients_are_in_the_flu_hpv_session
    @patient_consented_for_flu_nasal =
      create(
        :patient,
        :consent_given_nasal_only_triage_not_needed,
        :in_attendance,
        programmes: [@session.programmes.first],
        year_group: 3,
        session: @session
      )

    @patient_consented_for_flu_injection =
      create(
        :patient,
        :consent_given_without_gelatine_triage_not_needed,
        :in_attendance,
        programmes: [@session.programmes.first],
        year_group: 4,
        session: @session
      )

    @patient_consented_for_flu_both =
      create(
        :patient,
        :consent_given_nasal_or_injection_triage_not_needed,
        :in_attendance,
        programmes: [@session.programmes.first],
        year_group: 5,
        session: @session
      )

    @patient_consented_for_flu_both_triaged_nasal =
      create(
        :patient,
        :consent_given_injection_and_nasal_triage_safe_to_vaccinate_nasal,
        :in_attendance,
        programmes: [@session.programmes.first],
        year_group: 5,
        session: @session
      )

    @patient_consented_for_hpv_and_flu_injection =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        year_group: 8,
        session: @session
      ).tap do
        it
          .consent_statuses
          .find_by(programme_type: @session.programme_types.first)
          .update!(without_gelatine: true)
      end
  end

  def and_patients_are_in_the_doubles_session
    @patient_consented_for_doubles =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        year_group: 9,
        session: @session
      )
    @patient_consented_for_doubles_triaged_safe_to_vaccinate =
      create(
        :patient,
        :consent_given_triage_safe_to_vaccinate,
        :in_attendance,
        year_group: 10,
        session: @session
      )
  end

  def when_i_visit_the_record_vaccinations_tab
    sign_in @nurse
    visit session_record_path(@session)
  end

  def and_i_see_all_the_patients_in_flu_hpv_session
    expect(page).to have_content(@patient_consented_for_flu_nasal.full_name)
    expect(page).to have_content(@patient_consented_for_flu_injection.full_name)
    expect(page).to have_content(
      @patient_consented_for_flu_both_triaged_nasal.full_name
    )
    expect(page).to have_content(
      @patient_consented_for_hpv_and_flu_injection.full_name
    )
  end

  def then_i_see_all_the_patients_in_doubles_session
    expect(page).to have_content(@patient_consented_for_doubles.full_name)
    expect(page).to have_content(
      @patient_consented_for_doubles_triaged_safe_to_vaccinate.full_name
    )
  end

  def and_i_dont_see_vaccine_criteria_filter_radios
    expect(page).not_to have_field("Injection only", type: "radio")
    expect(page).not_to have_field("Nasal spray only", type: "radio")
    expect(page).not_to have_field("Nasal spray preferred", type: "radio")
  end

  def when_i_filter_on_nasal_spray_only
    uncheck "Nasal spray only"
    uncheck "Nasal spray preferred"
    uncheck "Injection only"
    check "Nasal spray only"
    click_on "Update results"
  end

  def when_i_filter_on_nasal_spray_preferred
    uncheck "Nasal spray only"
    uncheck "Nasal spray preferred"
    uncheck "Injection only"
    check "Nasal spray preferred"
    click_on "Update results"
  end

  def when_i_filter_on_injection_only
    uncheck "Nasal spray only"
    uncheck "Nasal spray preferred"
    uncheck "Injection only"
    check "Injection only"
    click_on "Update results"
  end

  def then_i_see_only_the_patients_eligible_for_nasal_spray_only
    expect(page).not_to have_content(
      @patient_consented_for_hpv_and_flu_injection.full_name
    )
    expect(page).not_to have_content(
      @patient_consented_for_flu_injection.full_name
    )
    expect(page).to have_content(@patient_consented_for_flu_nasal.full_name)
    expect(page).not_to have_content(@patient_consented_for_flu_both.full_name)
    expect(page).to have_content(
      @patient_consented_for_flu_both_triaged_nasal.full_name
    )
  end

  def then_i_see_only_the_patients_eligible_for_nasal_spray_preferred
    expect(page).not_to have_content(
      @patient_consented_for_hpv_and_flu_injection.full_name
    )
    expect(page).not_to have_content(
      @patient_consented_for_flu_injection.full_name
    )
    expect(page).not_to have_content(@patient_consented_for_flu_nasal.full_name)
    expect(page).to have_content(@patient_consented_for_flu_both.full_name)
    expect(page).not_to have_content(
      @patient_consented_for_flu_both_triaged_nasal.full_name
    )
  end

  def then_i_see_only_the_patients_eligible_for_injection_only
    expect(page).to have_content(
      @patient_consented_for_hpv_and_flu_injection.full_name
    )
    expect(page).to have_content(@patient_consented_for_flu_injection.full_name)
    expect(page).not_to have_content(@patient_consented_for_flu_nasal.full_name)
    expect(page).not_to have_content(@patient_consented_for_flu_both.full_name)
    expect(page).not_to have_content(
      @patient_consented_for_flu_both_triaged_nasal.full_name
    )
  end

  def and_i_filter_on_flu_and_nasal
    check "Flu"
    uncheck "HPV"
    uncheck "Nasal spray only"
    uncheck "Nasal spray preferred"
    uncheck "Injection only"
    check "Nasal spray only"
    click_on "Update results"
  end

  def when_i_filter_on_hpv_and_injection
    uncheck "Flu"
    check "HPV"
    uncheck "Nasal spray only"
    uncheck "Nasal spray preferred"
    uncheck "Injection only"
    check "Injection only"
    click_on "Update results"
  end

  def when_i_filter_on_flu_and_injection
    check "Flu"
    uncheck "HPV"
    uncheck "Nasal spray only"
    uncheck "Nasal spray preferred"
    uncheck "Injection only"
    check "Injection only"
    click_on "Update results"
  end

  def when_i_filter_on_hpv_and_nasal
    check "HPV"
    uncheck "Flu"
    uncheck "Nasal spray only"
    uncheck "Nasal spray preferred"
    uncheck "Injection only"
    check "Nasal spray only"
    click_on "Update results"
  end

  def then_i_see_only_flu_patients_eligible_for_nasal
    expect(page).to have_content(@patient_consented_for_flu_nasal.full_name)
    expect(page).to have_content(
      @patient_consented_for_flu_both_triaged_nasal.full_name
    )
    expect(page).not_to have_content(
      @patient_consented_for_flu_injection.full_name
    )
    expect(page).not_to have_content(
      @patient_consented_for_hpv_and_flu_injection.full_name
    )
  end

  def then_i_see_only_hpv_patients_eligible_for_injection
    expect(page).to have_content(
      @patient_consented_for_hpv_and_flu_injection.full_name
    )
    expect(page).not_to have_content(@patient_consented_for_flu_nasal.full_name)
    expect(page).not_to have_content(
      @patient_consented_for_flu_injection.full_name
    )
    expect(page).not_to have_content(
      @patient_consented_for_flu_both_triaged_nasal.full_name
    )
  end

  def then_i_see_only_flu_patients_eligible_for_injection
    expect(page).to have_content(@patient_consented_for_flu_injection.full_name)
    expect(page).to have_content(
      @patient_consented_for_hpv_and_flu_injection.full_name
    )
    expect(page).not_to have_content(@patient_consented_for_flu_nasal.full_name)
    expect(page).not_to have_content(
      @patient_consented_for_flu_both_triaged_nasal.full_name
    )
  end

  def then_i_see_no_patients
    expect(page).to have_content("No children matching search criteria found")
  end
end
