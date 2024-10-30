# frozen_string_literal: true

describe "Self-consent" do
  before { Flipper.enable(:release_1b) }

  after do
    Flipper.disable(:release_1b)
    travel_back
  end

  scenario "No consent from parent, the child is Gillick competent so can self-consent" do
    given_an_hpv_programme_is_underway
    and_it_is_the_day_of_a_vaccination_session
    and_there_is_a_child_without_parental_consent

    when_the_nurse_assesses_the_child_as_gillick_competent
    then_the_child_can_give_their_own_consent_that_the_nurse_records

    when_the_nurse_views_the_childs_record
    then_they_see_that_the_child_has_consent
    and_the_details_of_the_gillick_competence_assessment_are_visible
    and_the_child_should_be_safe_to_vaccinate
  end

  def given_an_hpv_programme_is_underway
    programme = create(:programme, :hpv)
    @team =
      create(
        :team,
        :with_one_nurse,
        programmes: [programme],
        nurse_email: "nurse.joy@example.com"
      )
    location = create(:location, :school, name: "Pilot School")
    @session = create(:session, :scheduled, team: @team, programme:, location:)
    @child = create(:patient, session: @session)
  end

  def and_it_is_the_day_of_a_vaccination_session
    travel_to(@session.dates.min)
  end

  def and_there_is_a_child_without_parental_consent
    sign_in @team.users.first

    visit "/dashboard"

    click_on "Programmes", match: :first
    click_on "HPV"
    within ".app-secondary-navigation" do
      click_on "Sessions"
    end
    click_on "Pilot School"
    click_on "Check consent responses"

    expect(page).to have_content("No response ( 1 )")
    expect(page).to have_content(@child.full_name)
  end

  def when_the_nurse_assesses_the_child_as_gillick_competent
    click_on @child.full_name
    click_link "Give your assessment"

    click_through_guidance
    record_competence
    record_details_of_assessment
    check_and_confirm
  end

  def click_through_guidance
    expect(page).to have_content("Assessing Gillick competence")
    click_button "Give your assessment"
  end

  def record_competence
    # try submitting without filling in the form
    click_on "Continue"
    expect(page).to have_content("There is a problem")
    expect(page).to have_content("Choose if they are Gillick competent")

    choose "Yes, they are Gillick competent"
    click_on "Continue"
  end

  def record_details_of_assessment
    # try submitting without filling in the form
    click_on "Continue"
    expect(page).to have_content("Enter details of your assessment")

    fill_in "Details of your assessment",
            with: "They understand the benefits and risks of the vaccine"
    click_on "Continue"
  end

  def check_and_confirm
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content(
      ["Are they Gillick competent?", "Yes, they are Gillick competent"].join
    )
    expect(page).to have_content(
      [
        "Details of your assessment",
        "They understand the benefits and risks of the vaccine"
      ].join
    )
    click_on "Save changes"
  end

  def then_the_child_can_give_their_own_consent_that_the_nurse_records
    click_on "Get consent"

    # record consent
    choose "Yes, they agree"
    click_on "Continue"

    # answer the health questions
    all("label", text: "No").each(&:click)
    click_on "Continue"

    choose "Yes, it’s safe to vaccinate"
    click_on "Continue"

    # confirmation page
    click_on "Confirm"

    expect(page).to have_content("Check consent responses")
    expect(page).to have_content("Consent given ( 1 )")
  end

  def when_the_nurse_views_the_childs_record
    click_on @child.full_name
  end

  def then_they_see_that_the_child_has_consent
    expect(page).to have_content(
      "#{@child.full_name} Child (Gillick competent)"
    )
    expect(page).to have_content("Consent given")
  end

  def and_the_details_of_the_gillick_competence_assessment_are_visible
    expect(page).to have_content("Yes, they are Gillick competent")
    expect(page).to have_content(
      "They understand the benefits and risks of the vaccine"
    )

    click_on @child.full_name
    expect(page).not_to have_content("Parent or guardian")
    click_on "Back to patient page"
  end

  def and_the_child_should_be_safe_to_vaccinate
    expect(page).to have_content("Safe to vaccinate")
  end
end
