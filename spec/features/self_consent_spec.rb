# frozen_string_literal: true

describe "Self-consent" do
  before { Flipper.enable(:release_1b) }
  after { Flipper.disable(:release_1b) }

  scenario "No consent from parent, the child is Gillick competent so can self-consent" do
    given_an_hpv_programme_is_underway
    and_there_is_a_child_without_parental_consent

    when_the_nurse_assesses_the_child_as_not_being_gillick_competent
    and_the_details_of_the_gillick_non_competence_assessment_are_visible
    then_the_nurse_assesses_the_child_as_gillick_competent
    then_the_child_can_give_their_own_consent_that_the_nurse_records

    when_the_nurse_views_the_childs_record
    then_they_see_that_the_child_has_consent
    and_the_child_should_be_safe_to_vaccinate
  end

  scenario "No consent from parent, the child is not Gillick competent" do
    given_an_hpv_programme_is_underway
    and_there_is_a_child_without_parental_consent

    when_the_nurse_assesses_the_child_as_gillick_competent
    and_the_details_of_the_gillick_competence_assessment_are_visible
    then_the_nurse_assesses_the_child_as_not_being_gillick_competent
    then_the_child_cannot_give_their_own_consent
    and_the_childs_status_reflects_that_there_is_no_consent
  end

  def given_an_hpv_programme_is_underway
    programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [programme])

    @school = create(:location, :school)

    @session =
      create(
        :session,
        :today,
        organisation: @organisation,
        programme:,
        location: @school
      )

    @patient = create(:patient, session: @session)
  end

  def and_there_is_a_child_without_parental_consent
    sign_in @organisation.users.first

    visit "/dashboard"

    click_on "Programmes", match: :first
    click_on "HPV"
    within ".app-secondary-navigation" do
      click_on "Sessions"
    end
    click_on @school.name
    click_on "Check consent responses"

    expect(page).to have_content("No response ( 1 )")
    expect(page).to have_content(@patient.full_name)
  end

  def when_the_nurse_assesses_the_child_as_gillick_competent
    click_on @patient.full_name
    click_on "Assess Gillick competence"
    fill_in_as_competent
    click_on "Complete your assessment"
  end

  def then_the_nurse_assesses_the_child_as_gillick_competent
    click_on "Edit Gillick competence"
    fill_in_as_competent
    click_on "Update your assessment"
  end

  def fill_in_as_competent
    within(
      "fieldset",
      text: "The child knows which vaccination they will have"
    ) { choose "Yes" }

    within(
      "fieldset",
      text: "The child knows which disease the vaccination protects against"
    ) { choose "Yes" }

    within(
      "fieldset",
      text: "The child knows what could happen if they got the disease"
    ) { choose "Yes" }

    within(
      "fieldset",
      text: "The child knows how the injection will be given"
    ) { choose "Yes" }

    within(
      "fieldset",
      text: "The child knows which side effects they might experience"
    ) { choose "Yes" }

    fill_in "Assessment notes (optional)",
            with: "They understand the benefits and risks of the vaccine"
  end

  def when_the_nurse_assesses_the_child_as_not_being_gillick_competent
    click_on @patient.full_name
    click_on "Assess Gillick competence"
    fill_in_as_non_competent
    click_on "Complete your assessment"
  end

  def then_the_nurse_assesses_the_child_as_not_being_gillick_competent
    click_on "Edit Gillick competence"
    fill_in_as_non_competent
    click_on "Update your assessment"
  end

  def fill_in_as_non_competent
    within(
      "fieldset",
      text: "The child knows which vaccination they will have"
    ) { choose "No" }

    within(
      "fieldset",
      text: "The child knows which disease the vaccination protects against"
    ) { choose "No" }

    within(
      "fieldset",
      text: "The child knows what could happen if they got the disease"
    ) { choose "No" }

    within(
      "fieldset",
      text: "The child knows how the injection will be given"
    ) { choose "No" }

    within(
      "fieldset",
      text: "The child knows which side effects they might experience"
    ) { choose "No" }

    fill_in "Assessment notes (optional)",
            with: "They didn't understand the benefits and risks of the vaccine"
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
    click_on @patient.full_name
  end

  def then_they_see_that_the_child_has_consent
    expect(page).to have_content(
      "#{@patient.full_name} Child (Gillick competent)"
    )
    expect(page).to have_content("Consent given")
  end

  def and_the_details_of_the_gillick_competence_assessment_are_visible
    expect(page).to have_content("Child assessed as Gillick competent")
    expect(page).to have_content(
      "They understand the benefits and risks of the vaccine"
    )
  end

  def and_the_details_of_the_gillick_non_competence_assessment_are_visible
    expect(page).to have_content("Child assessed as not Gillick competent")
    expect(page).to have_content(
      "They didn't understand the benefits and risks of the vaccine"
    )
  end

  def and_the_child_should_be_safe_to_vaccinate
    expect(page).to have_content("Safe to vaccinate")
  end

  def then_the_child_cannot_give_their_own_consent
    click_on "Get consent"
    expect(page).to have_content("Who are you trying to get consent from?")
    expect(page).not_to have_content(
      "Do they agree to them having the HPV vaccination?"
    )
    click_on "Back"
  end

  def and_the_childs_status_reflects_that_there_is_no_consent
    expect(page).to have_content("No response")
  end
end
