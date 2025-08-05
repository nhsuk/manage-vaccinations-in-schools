# frozen_string_literal: true

describe "Today’s batch" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  before { given_i_am_signed_in }

  scenario "injection only" do
    when_i_vaccinate_a_patient_with_hpv
    and_i_choose_a_default_batch(@hpv_batch)
    then_i_see_the_default_batch_banner_with_batch_1

    when_i_click_the_change_batch_link
    then_i_see_the_change_batch_page

    when_i_choose_the_second_batch
    then_i_see_the_default_batch_banner_with_batch_2

    when_i_vaccinate_a_second_patient_with_hpv
    then_i_see_the_default_batch_on_the_confirmation_page
    and_i_see_the_default_batch_on_the_patient_page

    when_i_vaccinate_a_patient_with_flu
    then_i_am_required_to_choose_a_batch
  end

  scenario "nasal spray and injection" do
    when_i_vaccinate_a_patient_with_flu
    then_i_dont_see_the_batch(@flu_nasal_batch)
    and_i_choose_a_default_batch(@flu_injection_batch)

    when_i_vaccinate_a_second_patient_with_flu
    then_i_am_required_to_choose_a_batch
    and_i_dont_see_the_batch(@flu_injection_batch)
    and_i_choose_a_default_batch(@flu_nasal_batch)
    then_i_see_the_default_flu_batches_banner
  end

  def given_i_am_signed_in
    flu_programme = create(:programme, :flu)
    hpv_programme = create(:programme, :hpv)

    programmes = [hpv_programme, flu_programme]

    team = create(:team, :with_one_nurse, programmes:)

    batches =
      programmes.map do |programme|
        programme.vaccines.flat_map do |vaccine|
          create_list(:batch, 2, :not_expired, team:, vaccine:)
        end
      end

    @hpv_batch = batches.first.first
    @hpv_batch2 = batches.first.second
    @flu_injection_batch = batches.second.find { it.vaccine.injection? }
    @flu_nasal_batch = batches.second.find { it.vaccine.nasal? }

    @session = create(:session, team:, programmes:)

    @patient =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session,
        year_group: 9
      )

    @patient2 =
      create(
        :patient,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session,
        year_group: 8
      )

    @patient2.consent_status(
      programme: flu_programme,
      academic_year: Date.current.academic_year
    ).update!(vaccine_methods: %w[nasal])

    sign_in team.users.first
  end

  def when_i_vaccinate_a_patient_with_hpv
    visit session_record_path(@session)

    click_link @patient.full_name
    click_on "HPV"

    within all("section")[0] do
      check "I have checked that the above statements are true"
    end

    within all("section")[1] do
      choose "Yes"
      choose "Left arm (upper position)"
      click_button "Continue"
    end
  end

  def then_i_dont_see_the_batch(batch)
    expect(page).not_to have_content(batch.name)
  end

  alias_method :and_i_dont_see_the_batch, :then_i_dont_see_the_batch

  def and_i_choose_a_default_batch(batch)
    choose batch.name

    # Find the selected radio button element
    selected_radio_button = find(:radio_button, batch.name, checked: true)

    # Find the "Default to this batch for this session" checkbox immediately below and check it
    checkbox_below =
      selected_radio_button.find(
        :xpath,
        'following::input[@type="checkbox"][1]'
      )
    checkbox_below.check
    click_button "Continue"

    click_button "Confirm"

    # back to session
    click_on "Record vaccinations"
  end

  def when_i_vaccinate_a_second_patient_with_hpv
    visit session_record_path(@session)

    click_link @patient2.full_name
    click_on "HPV"

    within all("section")[0] do
      check "I have checked that the above statements are true"
    end

    within all("section")[1] do
      choose "Yes"
      choose "Left arm (upper position)"
      click_button "Continue"
    end
  end

  def then_i_see_the_default_batch_banner_with_batch_1
    expect(page).to have_content("Gardasil 9 (HPV): #{@hpv_batch.name}")
  end

  def then_i_see_the_default_batch_banner_with_batch_2
    expect(page).to have_content("Gardasil 9 (HPV): #{@hpv_batch2.name}")
  end

  def when_i_click_the_change_batch_link
    click_link "Change default batch"
  end

  def then_i_see_the_change_batch_page
    expect(page).to have_content("Select a default HPV batch for this session")
    expect(page).to have_selector(:label, @hpv_batch.name)
    expect(page).to have_selector(:label, @hpv_batch2.name)
  end

  def when_i_choose_the_second_batch
    choose @hpv_batch2.name
    click_button "Continue"
  end

  def then_i_see_the_default_batch_on_the_confirmation_page
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content(@hpv_batch2.name)

    click_button "Confirm"
  end

  def and_i_see_the_default_batch_on_the_patient_page
    expect(page).to have_content("Vaccinated")

    click_on "1 February 2024"
    expect(page).to have_content(@hpv_batch2.name)
  end

  def when_i_vaccinate_a_patient_with_flu
    visit session_record_path(@session)

    click_link @patient.full_name
    click_on "Flu"

    within all("section")[0] do
      check "I have checked that the above statements are true"
    end

    within all("section")[1] do
      choose "Yes"
      choose "Left arm (upper position)"
      click_button "Continue"
    end
  end

  def when_i_vaccinate_a_second_patient_with_flu
    visit session_record_path(@session)

    click_link @patient2.full_name
    click_on "Flu"

    within all("section")[0] do
      check "I have checked that the above statements are true"
    end

    within all("section")[1] do
      choose "Yes"
      click_button "Continue"
    end
  end

  def then_i_am_required_to_choose_a_batch
    expect(page).to have_content("Which batch did you use?")
  end

  def then_i_see_the_default_flu_batches_banner
    expect(page).to have_content(
      "Cell-based Trivalent Influenza Vaccine Seqirus (flu injection): #{@flu_injection_batch.name}"
    )
    expect(page).to have_content(
      "Fluenz (flu nasal spray): #{@flu_nasal_batch.name}"
    )
  end
end
