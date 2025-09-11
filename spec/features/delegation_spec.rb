# frozen_string_literal: true

describe "Delegation" do
  scenario "in a HPV session" do
    given_an_hpv_session_exists

    when_i_visit_the_session_as_a_nurse
    and_i_go_to_the_edit_page
    then_i_see_nothing_about_delegation
  end

  scenario "in a flu session" do
    given_a_flu_session_exists

    when_i_visit_the_session_as_a_nurse
    and_i_go_to_the_edit_page
    then_i_see_the_delegation_options

    when_i_enable_delegation
    then_i_see_the_options_are_enabled
  end

  def given_a_flu_session_exists
    @programme = create(:programme, :flu)
    @team = create(:team, programmes: [@programme])
    @nurse = create(:nurse, teams: [@team])

    @session = create(:session, programmes: [@programme], team: @team)
  end

  def given_an_hpv_session_exists
    @programme = create(:programme, :hpv)
    @team = create(:team, programmes: [@programme])
    @nurse = create(:nurse, teams: [@team])

    @session = create(:session, programmes: [@programme], team: @team)
  end

  def when_i_visit_the_session_as_a_nurse
    sign_in @nurse
    visit session_path(@session)
  end

  def and_i_go_to_the_edit_page
    click_on "Edit session"
  end

  def then_i_see_nothing_about_delegation
    expect(page).not_to have_content("patient specific direction")
    expect(page).not_to have_content("national protocol")
  end

  def then_i_see_the_delegation_options
    expect(page).to have_content("Use patient specific direction (PSD)")
    expect(page).to have_content("Use national protocol")
  end

  def when_i_enable_delegation
    click_on "Change use patient specific direction (PSD)"

    # PSD
    within all(".nhsuk-fieldset")[0] do
      choose "Yes"
    end

    # National protocol
    within all(".nhsuk-fieldset")[1] do
      choose "Yes"
    end

    click_on "Continue"
  end

  def then_i_see_the_options_are_enabled
    expect(page).to have_content("Use patient specific direction (PSD)Yes")
    expect(page).to have_content("Use national protocolYes")
  end
end
