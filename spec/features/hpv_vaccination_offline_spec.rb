# frozen_string_literal: true

describe "HPV Vaccination" do
  before { Flipper.enable(:release_1b) }
  after { Flipper.disable(:release_1b) }

  scenario "Download spreadsheet" do
    given_an_hpv_programme_is_underway
    and_i_am_signed_in

    when_i_go_to_a_session
    and_i_click_record_offline
    then_i_see_a_csv_file

    # TODO: modify the file to add a vaccination
    # TODO: upload the file
    # TODO: check the vaccination appears
  end

  def given_an_hpv_programme_is_underway
    programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [programme])
    location = create(:location, :school)

    vaccine = programme.vaccines.active.first
    @batch = create(:batch, organisation: @organisation, vaccine:)

    @session =
      create(:session, organisation: @organisation, programme:, location:)
    @patient =
      create(:patient, :consent_given_triage_not_needed, session: @session)
  end

  def and_i_am_signed_in
    sign_in @organisation.users.first
  end

  def when_i_go_to_a_session
    visit session_path(@session)
  end

  def and_i_click_record_offline
    click_link "Record offline (CSV)"
  end

  def then_i_see_a_csv_file
    expect(page.status_code).to eq(200)

    # check headers look right
    expect(page).to have_content("ORGANISATION_CODE")
  end
end
