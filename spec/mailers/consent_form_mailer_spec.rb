require "rails_helper"

RSpec.describe ConsentFormMailer, type: :mailer do
  describe "#confirmation_injection" do
    it "calls template_mail with correct personalisation" do
      mail =
        described_class.confirmation_injection(
          build(
            :consent_form,
            reason: :contains_gelatine,
            session: create(:session, campaign: create(:campaign, :flu))
          )
        )

      expect(mail.message.header["personalisation"].unparsed_value).to include(
        reason_for_refusal: "of the gelatine in the nasal spray"
      )
    end
  end
end
