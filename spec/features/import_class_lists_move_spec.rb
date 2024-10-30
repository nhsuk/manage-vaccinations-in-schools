# frozen_string_literal: true

describe "Import class lists - Moving patients" do
  around { |example| travel_to(Date.new(2023, 5, 20)) { example.run } }

  scenario "User uploads a file and moves patients to a new session" do
    given_an_hpv_programme_is_underway

    when_i_visit_a_session_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_session
    then_i_should_see_the_import_page

    when_i_upload_a_valid_file
    then_i_should_see_the_imports_page_with_the_completed_flash

    when_i_visit_a_different_session_page_for_the_hpv_programme
    and_i_start_adding_children_to_the_session
    and_i_upload_a_valid_file
    then_i_should_see_the_imports_page_with_the_completed_flash

    when_i_visit_a_session_page_for_the_hpv_programme
    then_i_should_see_pending_moves_out

    when_i_click_on_the_pending_moves_card
    then_i_should_see_the_patients_moving_out_tab

    when_i_click_on_the_moved_out_tab
    then_i_should_see_the_patients_moving_out_table

    when_i_confirm_a_move
    then_i_should_see_a_success_flash

    when_i_ignore_a_move
    then_i_should_see_a_notice_flash
  end

  def given_an_hpv_programme_is_underway
    @organisation = create(:organisation, :with_one_nurse)
    location =
      create(
        :location,
        :secondary,
        name: "Waterloo Road",
        organisation: @organisation
      )
    other_location =
      create(
        :location,
        :secondary,
        name: "Different Road",
        organisation: @organisation
      )
    @user = @organisation.users.first
    programme = create(:programme, :hpv, organisations: [@organisation])
    create(
      :session,
      :unscheduled,
      organisation: @organisation,
      location:,
      programme:
    )
    create(
      :session,
      :unscheduled,
      organisation: @organisation,
      location: other_location,
      programme:
    )
  end

  def when_i_visit_a_session_page_for_the_hpv_programme
    sign_in @user
    visit "/dashboard"
    click_on "Sessions", match: :first
    click_on "Unscheduled"
    click_on "Waterloo Road"
  end

  def when_i_visit_a_different_session_page_for_the_hpv_programme
    visit "/dashboard"
    click_on "Sessions", match: :first
    click_on "Unscheduled"
    click_on "Different Road"
  end

  def and_i_start_adding_children_to_the_session
    click_on "Import class list"
  end

  def then_i_should_see_the_import_page
    expect(page).to have_content("Import class list")
  end

  def when_i_upload_a_valid_file
    attach_file("class_import[csv]", "spec/fixtures/class_import/valid.csv")
    click_on "Continue"
  end
  alias_method :and_i_upload_a_valid_file, :when_i_upload_a_valid_file

  def when_i_go_to_the_upload_page
    click_on "Import class list"
  end

  def then_i_should_see_the_imports_page_with_the_completed_flash
    expect(page).to have_content("Import completed")
  end

  def then_i_should_see_pending_moves_out
    expect(page).to have_content("4 children left this school")
  end

  def when_i_click_on_the_pending_moves_card
    click_link "Review children who have changed schools"
  end

  def then_i_should_see_the_patients_moving_out_tab
    expect(page).to have_content("Moved out ( 4 )")
  end

  def when_i_click_on_the_moved_out_tab
    click_link "Moved out"
  end

  def then_i_should_see_the_patients_moving_out_table
    expect(page).to have_content("4 children left this school")
  end

  def when_i_confirm_a_move
    click_button "Confirm move", match: :first
  end

  def then_i_should_see_a_success_flash
    expect(page).to have_alert("Success")
  end

  def when_i_ignore_a_move
    click_button "Ignore move", match: :first
  end

  def then_i_should_see_a_notice_flash
    expect(page).to have_region("Information")
  end
end
