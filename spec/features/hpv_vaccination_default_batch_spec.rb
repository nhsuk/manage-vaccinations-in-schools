# frozen_string_literal: true

describe "HPV Vaccination" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "Default batch" do
    given_i_am_signed_in
    when_i_vaccinate_a_patient
    then_i_see_the_default_batch_banner_with_batch_1

    when_i_click_the_change_batch_link
    then_i_see_the_change_batch_page

    when_i_choose_the_second_batch
    then_i_see_the_default_batch_banner_with_batch_2

    when_i_vaccinate_a_second_patient
    then_i_see_the_default_batch_on_the_confirmation_page
    and_i_see_the_default_batch_on_the_patient_page
  end

  def given_i_am_signed_in
    programme = create(:example_programme, :in_progress, academic_year: 2023)
    team = programme.team
    @batch = programme.batches.first
    @batch2 = programme.batches.second
    @session = programme.sessions.first
    @patient, @patient2 =
      @session
        .patient_sessions
        .select { _1.state == "consent_given_triage_not_needed" }
        .slice(0, 2)
        .map(&:patient)

    sign_in team.users.first
  end

  def when_i_vaccinate_a_patient
    visit session_vaccinations_path(@session)
    click_link @patient.full_name

    choose "Yes, they got the HPV vaccine"
    choose "Left arm"
    click_button "Continue"

    choose @batch.name

    # Find the selected radio button element
    selected_radio_button = find(:radio_button, @batch.name, checked: true)

    # Find the "Default to this batch for this session" checkbox immediately below and check it
    checkbox_below =
      selected_radio_button.find(
        :xpath,
        'following::input[@type="checkbox"][1]'
      )
    checkbox_below.check
    click_button "Continue"

    click_button "Confirm"
  end

  def when_i_vaccinate_a_second_patient
    visit session_vaccinations_path(@session)
    click_link @patient2.full_name

    choose "Yes, they got the HPV vaccine"
    choose "Left arm"
    click_button "Continue"
  end

  def then_i_see_the_default_batch_banner_with_batch_1
    expect(page).to have_content(/You are currently using.*#{@batch.name}/)
  end

  def then_i_see_the_default_batch_banner_with_batch_2
    expect(page).to have_content(/You are currently using.*#{@batch2.name}/)
  end

  def when_i_click_the_change_batch_link
    click_link "Change the default batch"
  end

  def then_i_see_the_change_batch_page
    expect(page).to have_content("Select a default batch for this session")
    expect(page).to have_selector(:label, @batch.name)
    expect(page).to have_selector(:label, @batch2.name)
  end

  def when_i_choose_the_second_batch
    choose @batch2.name
    click_button "Continue"
  end

  def then_i_see_the_default_batch_on_the_confirmation_page
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content(@batch2.name)

    click_button "Confirm"
  end

  def and_i_see_the_default_batch_on_the_patient_page
    click_link @patient2.full_name

    expect(page).to have_content("Vaccinated")
    expect(page).to have_content(@batch2.name)
  end
end
