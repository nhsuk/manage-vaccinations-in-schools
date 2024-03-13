require "rails_helper"

describe FeedbackMailer do
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
        patient_session = build :patient_session
        session = patient_session.session
        consent =
          build(:consent, recorded_at: Date.new(2021, 1, 1), patient_session:)
        mail = described_class.give_feedback(consent:, session:)

        expect(
          mail.message.header["personalisation"].unparsed_value
        ).to include(survey_deadline_date: "8 January 2021")
      end
    end
  end
end
