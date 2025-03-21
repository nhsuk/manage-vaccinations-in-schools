# frozen_string_literal: true

describe "Paper consent" do
  scenario "Download the consent form" do
    given_i_am_signed_in

    when_i_click_download_consent_form
    then_i_download_a_pdf_consent_form
  end

  def given_i_am_signed_in
    programmes = [create(:programme, :hpv)]
    organisation = create(:organisation, :with_one_nurse, programmes:)
    @session = create(:session, organisation:, programmes:)

    sign_in organisation.users.first
  end

  def when_i_click_download_consent_form
    visit session_path(@session)
    click_on "Download the HPV consent form (PDF)"
  end

  def then_i_download_a_pdf_consent_form
    expect(page.status_code).to eq(200)

    # PDF files include this string at the start
    expect(page).to have_content("PDF")
  end
end
