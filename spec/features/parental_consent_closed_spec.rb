# frozen_string_literal: true

describe "Parental consent closed" do
  scenario "Consent form is shown as closed" do
    given_an_hpv_programme_is_underway_with_a_backfilled_session
    when_i_go_to_the_consent_form
    then_i_see_that_consent_is_closed
  end

  def given_an_hpv_programme_is_underway_with_a_backfilled_session
    @programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
    location = create(:location, :school, name: "Pilot School")
    @session =
      create(
        :session,
        :completed,
        programme: @programme,
        location:,
        date: Date.yesterday
      )
  end

  def when_i_go_to_the_consent_form
    visit start_parent_interface_consent_forms_path(@session, @programme)
  end

  def then_i_see_that_consent_is_closed
    expect(page).to have_content("The deadline for responding has passed")
  end
end
