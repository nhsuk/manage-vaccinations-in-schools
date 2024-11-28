# frozen_string_literal: true

describe "Manage batches" do
  before { Flipper.enable(:release_1b) }
  after { Flipper.disable(:release_1b) }

  around { |example| travel_to(Time.zone.local(2024, 2, 29)) { example.run } }

  scenario "Adding and editing batches" do
    given_my_organisation_is_running_an_hpv_vaccination_programme
    and_there_is_a_vaccination_session_today_with_one_patient_ready_to_vaccinate

    when_i_manage_vaccines
    then_i_see_only_active_hpv_vaccines_with_no_batches_set_up

    when_i_try_to_add_a_batch_with_an_invalid_expiry_date
    then_i_see_the_error_message

    when_i_add_a_valid_new_batch
    then_i_see_the_batch_i_just_added_on_the_vaccines_page

    when_i_edit_the_expiry_date_of_the_batch
    then_i_see_the_updated_expiry_date_on_the_vaccines_page

    when_i_archive_the_batch
    then_i_see_the_success_banner
    and_i_see_only_active_hpv_vaccines_with_no_batches_set_up

    when_i_add_the_archived_batch_again
    then_i_see_the_updated_expiry_date_on_the_vaccines_page
  end

  def given_my_organisation_is_running_an_hpv_vaccination_programme
    @programme = create(:programme, :hpv_all_vaccines)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
  end

  def and_there_is_a_vaccination_session_today_with_one_patient_ready_to_vaccinate
    location = create(:school)
    session = create(:session, :today, programme: @programme, location:)

    create(
      :patient_session,
      :consent_given_triage_not_needed,
      programme: @programme,
      session:
    )

    @patient = session.reload.patients.first
  end

  def when_i_manage_vaccines
    sign_in @organisation.users.first

    visit "/dashboard"
    click_on "Vaccines", match: :first
  end

  def then_i_see_only_active_hpv_vaccines_with_no_batches_set_up
    expect(page).to have_content("Gardasil 9 (HPV)")
    expect(page).not_to have_content("Cervarix (HPV)")
    expect(page).not_to have_css("table")
  end

  def when_i_try_to_add_a_batch_with_an_invalid_expiry_date
    click_on "Add a new batch", match: :first

    fill_in "Batch", with: "AB1234"

    # expiry date
    fill_in "Day", with: "0"
    fill_in "Month", with: "0"
    fill_in "Year", with: "0"

    click_on "Add batch"
  end

  def then_i_see_the_error_message
    expect(page).to have_content("There is a problem")
    expect(page).to have_content("Enter a year")
  end

  def when_i_add_a_valid_new_batch
    # expiry date
    fill_in "Day", with: "30"
    fill_in "Month", with: "3"
    fill_in "Year", with: "2024"

    click_on "Add batch"

    expect(page).to have_content("Batch AB1234 added")
  end

  def then_i_see_the_batch_i_just_added_on_the_vaccines_page
    expect(page).to have_content("Gardasil 9 (HPV)")
    expect(page).to have_css("table")
    expect(page).to have_content("AB1234 29 February 202430 March 2024")
  end

  def when_i_edit_the_expiry_date_of_the_batch
    click_on "Change"
    fill_in "Day", with: "31"
    fill_in "Month", with: "3"
    fill_in "Year", with: "2024"
    click_on "Save changes"
  end

  def then_i_see_the_updated_expiry_date_on_the_vaccines_page
    expect(page).to have_content("Gardasil 9 (HPV)")
    expect(page).to have_css("table")
    expect(page).to have_content("AB1234 29 February 202431 March 2024")
  end

  def when_i_archive_the_batch
    click_on "Archive"
    click_on "Yes, archive this batch"
  end

  def then_i_see_the_success_banner
    expect(page).to have_content("Batch archived")
  end

  def when_i_add_the_archived_batch_again
    click_on "Add a new batch", match: :first

    fill_in "Batch", with: "AB1234"

    fill_in "Day", with: "31"
    fill_in "Month", with: "3"
    fill_in "Year", with: "2024"

    click_on "Add batch"

    expect(page).to have_content("Batch AB1234 added")
  end

  alias_method :and_i_see_only_active_hpv_vaccines_with_no_batches_set_up,
               :then_i_see_only_active_hpv_vaccines_with_no_batches_set_up
end
