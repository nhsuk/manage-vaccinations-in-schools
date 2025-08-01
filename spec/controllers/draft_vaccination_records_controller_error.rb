# frozen_string_literal: true

feature "Draft vaccination controller errors", type: :feature do
  scenario "Go to draft vaccination record confirm with no open draft vaccination" do
    given_i_am_signed_in_with_flu_programme
    when_i_visit_draft_vaccination_record_confirm_with_no_active_record
    then_i_see_a_descriptive_error_message
  end

  def given_i_am_signed_in_with_flu_programme
    @programme = create(:programme, :flu)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
    sign_in @organisation.users.first
  end

  def when_i_visit_draft_vaccination_record_confirm_with_no_active_record
    visit "/draft-vaccination-record/confirm"
  end

  def then_i_see_a_descriptive_error_message
    expect(page).to have_content("Error: page not available")
    expect(page).to have_content("You do not have a vaccination record open, or it has timed out.")
  end
end