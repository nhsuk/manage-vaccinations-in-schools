# frozen_string_literal: true

describe "Vaccination" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "Today's batch" do
    given_i_am_signed_in

    when_i_vaccinate_a_patient_with_hpv
    then_i_see_the_default_batch_banner_with_batch_1

    when_i_click_the_change_batch_link
    then_i_see_the_change_batch_page

    when_i_choose_the_second_batch
    then_i_see_the_default_batch_banner_with_batch_2

    when_i_vaccinate_a_second_patient_with_hpv
    then_i_see_the_default_batch_on_the_confirmation_page
    and_i_see_the_default_batch_on_the_patient_page

    when_i_vaccinate_a_patient_with_menacwy
    then_i_am_required_to_choose_a_batch
  end

  def given_i_am_signed_in
    programmes = [create(:programme, :hpv), create(:programme, :menacwy)]

    organisation = create(:organisation, :with_one_nurse, programmes:)

    batches =
      programmes.map do |programme|
        programme.vaccines.flat_map do |vaccine|
          create_list(:batch, 2, :not_expired, organisation:, vaccine:)
        end
      end

    @hpv_batch = batches.first.first
    @hpv_batch2 = batches.first.second

    @session = create(:session, organisation:, programmes:)

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

    sign_in organisation.users.first
  end

  def when_i_vaccinate_a_patient_with_hpv
    visit session_record_path(@session)

    click_link @patient.full_name

    within all("section")[0] do
      check "I have checked that the above statements are true"
    end

    within all("section")[1] do
      choose "Yes"
      choose "Left arm (upper position)"
      click_button "Continue"
    end

    choose @hpv_batch.name

    # Find the selected radio button element
    selected_radio_button = find(:radio_button, @hpv_batch.name, checked: true)

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
    expect(page).to have_content("Select a default batch for this session")
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

  def when_i_vaccinate_a_patient_with_menacwy
    visit session_record_path(@session)

    click_link @patient.full_name
    click_on "MenACWY"

    within all("section")[0] do
      check "I have checked that the above statements are true"
    end

    within all("section")[1] do
      choose "Yes"
      choose "Left arm (upper position)"
      click_button "Continue"
    end
  end

  def then_i_am_required_to_choose_a_batch
    expect(page).to have_content("Which batch did you use?")
  end
end
