# frozen_string_literal: true

feature "Draft vaccination controller errors", type: :feature do
  [
    "/draft-vaccination-record/batch",
    "/draft-vaccination-record/date_and_time",
    "/draft-vaccination-record/outcome",
    "/draft-vaccination-record/confirm",
    "/draft-consent/questions",
    "/draft-consent/triage",
    "/draft-consent/confirm"
  ].each do |url_path|
    scenario "Go to #{url_path} with no open draft" do
      given_i_am_signed_in_with_flu_programme
      when_i_visit_url_with_no_draft_object_in_progress(url_path)
      then_i_see_a_descriptive_error_message
    end
  end

  def given_i_am_signed_in_with_flu_programme
    @programme = create(:programme, :flu)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
    sign_in @organisation.users.first
  end

  def when_i_visit_url_with_no_draft_object_in_progress(url_path)
    visit url_path
  end

  def then_i_see_a_descriptive_error_message
    expect(page).to have_content("Error: page not available")
    expect(page).to have_content("You do not have a draft page open, or it has timed out.")
  end
end