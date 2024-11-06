# frozen_string_literal: true

describe "Withdraw consent" do
  before { Flipper.enable(:release_1b) }
  after { Flipper.disable(:release_1b) }

  scenario "Already given" do
    given_i_am_signed_in
    and_consent_has_been_given

    when_i_go_to_the_patient
    then_i_see_the_patient
    and_i_see_the_consent
    and_i_am_able_to_record_a_vaccination

    when_i_click_on_the_consent
    then_i_see_the_consent
    and_i_click_withdraw_consent

    when_i_choose_a_reason
    and_i_fill_in_the_notes
    and_i_click_withdraw_consent
    then_i_see_the_consent_has_been_withdrawn
    and_i_cant_withdraw

    when_i_click_back
    then_i_see_the_patient
    and_i_see_the_consent
    and_i_am_not_able_to_record_a_vaccination
  end

  def given_i_am_signed_in
    @programme = create(:programme, :hpv)
    organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])

    @session = create(:session, organisation:, programme: @programme)
    @patient = create(:patient, session: @session)

    sign_in organisation.users.first
  end

  def and_consent_has_been_given
    @parent = @patient.parents.first
    @consent =
      create(
        :consent,
        :recorded,
        :given,
        patient: @patient,
        parent: @parent,
        programme: @programme
      )
  end

  def and_i_am_able_to_record_a_vaccination
    expect(page).to have_content("Ready for nurse")
    expect(page).to have_content("Did they get the HPV vaccine?")
  end

  def when_i_go_to_the_patient
    visit session_consents_path(@session)
    click_on "Consent given"
    click_link @patient.full_name
  end

  def then_i_see_the_patient
    expect(page).to have_content(@patient.full_name)
  end

  def then_i_see_the_consent
    expect(page).to have_content(@parent.full_name)
  end

  alias_method :and_i_see_the_consent, :then_i_see_the_consent

  def when_i_click_on_the_consent
    click_on @parent.full_name
  end

  def and_i_click_withdraw_consent
    click_on "Withdraw consent"
  end

  def when_i_choose_a_reason
    choose "Medical reasons"
  end

  def and_i_fill_in_the_notes
    fill_in "Notes", with: "Some notes."
  end

  def then_i_see_the_consent_has_been_withdrawn
    expect(page).to have_content("Withdrawn")
  end

  def and_i_cant_withdraw
    expect(page).not_to have_content("Withdraw consent")
  end

  def when_i_click_back
    click_on "Back"
  end

  def and_i_am_not_able_to_record_a_vaccination
    expect(page).to have_content("Consent refused")
    expect(page).not_to have_content("Did they get the HPV vaccine?")
  end
end
