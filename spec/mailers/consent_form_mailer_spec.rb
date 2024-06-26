# frozen_string_literal: true

require "rails_helper"

describe ConsentFormMailer, type: :mailer do
  describe "#confirmation_injection" do
    it "calls template_mail with correct reason_for_refusal" do
      mail =
        described_class.confirmation_injection(
          consent_form:
            build(
              :consent_form,
              response: "refused",
              reason: :contains_gelatine,
              recorded_at: Date.new(2021, 1, 1),
              session: create(:session, campaign: create(:campaign, :flu))
            )
        )

      expect(mail.message.header["personalisation"].unparsed_value).to include(
        reason_for_refusal: "of the gelatine in the nasal spray"
      )
    end
  end

  describe "#give_feedback" do
    context "with a consent form" do
      it "calls template_mail with correct survey_deadline_date" do
        consent_form = build(:consent_form, recorded_at: Date.new(2021, 1, 1))
        mail = described_class.give_feedback(consent_form:)

        expect(
          mail.message.header["personalisation"].unparsed_value
        ).to include(survey_deadline_date: "8 January 2021")
      end
    end

    context "with a consent record" do
      it "calls template_mail with correct survey_deadline_date" do
        session = build :session
        consent = build(:consent, recorded_at: Date.new(2021, 1, 1))
        mail = described_class.give_feedback(consent:, session:)

        expect(
          mail.message.header["personalisation"].unparsed_value
        ).to include(survey_deadline_date: "8 January 2021")
      end
    end
  end
end
