# frozen_string_literal: true

describe AppConsentConfirmationComponent do
  subject(:rendered) { render_inline(component) }

  let(:consent_form) { create(:consent_form) }
  let(:component) { described_class.new(consent_form) }

  it { should have_text("Consent confirmed") }

  it "informs the user a confirmation email will be sent" do
    expect(rendered).to have_text(
      "We've sent a confirmation to #{consent_form.parent_email}"
    )
  end

  context "consent for only MenACWY" do
    let(:session) do
      create(
        :session,
        dates: [Date.yesterday, Date.tomorrow],
        programmes: [create(:programme, :menacwy), create(:programme, :td_ipv)]
      )
    end
    let(:consent_form) { create(:consent_form, :given, session:) }

    before do
      consent_form.consent_form_programmes.first.update!(response: "given")
      consent_form.consent_form_programmes.second.update!(response: "refused")
    end

    it { should have_text("Consent for the MenACWY vaccination confirmed") }

    it "informs the user that their child is due a vaccination" do
      expect(rendered).to have_text(
        "#{consent_form.given_name} #{consent_form.family_name} is due to get " \
          "the MenACWY vaccination at school on " \
          "#{session.dates.second.to_fs(:short_day_of_week)}"
      )
    end
  end

  context "consent for MenACWY and Td/IPV" do
    let(:session) do
      create(
        :session,
        dates: [Date.yesterday, Date.tomorrow],
        programmes: [create(:programme, :menacwy), create(:programme, :td_ipv)]
      )
    end
    let(:consent_form) { create(:consent_form, response: "given", session:) }

    it { should have_text("Consent confirmed") }

    it "informs the user that their child is due a vaccination" do
      expect(rendered).to have_text(
        "#{consent_form.given_name} #{consent_form.family_name} is due to get " \
          "the MenACWY and Td/IPV vaccinations at school on " \
          "#{session.dates.second.to_fs(:short_day_of_week)}"
      )
    end
  end

  context "consent refused for HPV" do
    let(:session) { create(:session, programmes: [create(:programme, :hpv)]) }
    let(:consent_form) { create(:consent_form, response: "refused", session:) }

    it { should have_text("Consent refused") }

    it "informs the user that they have refused consent" do
      expect(rendered).to have_text(
        "You’ve told us that you do not want #{consent_form.given_name} " \
          "#{consent_form.family_name} to get the HPV vaccination at school"
      )
    end
  end

  context "consent refused for MenACWY and Td/IPV" do
    let(:session) do
      create(
        :session,
        programmes: [create(:programme, :menacwy), create(:programme, :td_ipv)]
      )
    end
    let(:consent_form) { create(:consent_form, response: "refused", session:) }

    it { should have_text("Consent refused") }

    it "informs the user that they have refused consent" do
      expect(rendered).to have_text(
        "You’ve told us that you do not want #{consent_form.given_name} " \
          "#{consent_form.family_name} to get the MenACWY and Td/IPV " \
          "vaccinations at school"
      )
    end
  end

  context "multiple session dates" do
    let(:session) do
      create(
        :session,
        programmes: [create(:programme, :hpv)],
        dates: [10.days.from_now, 11.days.from_now, 13.days.from_now]
      )
    end
    let(:consent_form) { create(:consent_form, response: "given", session:) }

    it "lists the session dates" do
      expect(rendered).to have_text(
        "at school on #{10.days.from_now.to_date.to_fs(:short_day_of_week)}, " \
          "#{11.days.from_now.to_date.to_fs(:short_day_of_week)} or " \
          "#{13.days.from_now.to_date.to_fs(:short_day_of_week)}"
      )
    end
  end
end
