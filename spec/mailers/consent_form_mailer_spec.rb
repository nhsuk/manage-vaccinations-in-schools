# frozen_string_literal: true

describe ConsentFormMailer do
  describe "#confirmation_injection" do
    subject(:mail) do
      described_class.with(consent_form:).confirmation_injection
    end

    let(:consent_form) do
      create(
        :consent_form,
        :recorded,
        :refused,
        reason: :contains_gelatine,
        session: create(:session, programme: create(:programme, :flu))
      )
    end

    it "calls template_mail with correct reason_for_refusal" do
      expect(mail.message.header["personalisation"].unparsed_value).to include(
        reason_for_refusal: "of the gelatine in the nasal spray"
      )
    end
  end

  describe "#give_feedback" do
    context "with a consent form" do
      subject(:mail) { described_class.with(consent_form:).give_feedback }

      let(:consent_form) do
        create(:consent_form, :recorded, recorded_at: Date.new(2021, 1, 1))
      end

      it "calls template_mail with correct survey_deadline_date" do
        expect(
          mail.message.header["personalisation"].unparsed_value
        ).to include(survey_deadline_date: "8 January 2021")
      end
    end

    context "with a consent record" do
      subject(:mail) { described_class.with(consent:, session:).give_feedback }

      let(:session) { create(:session) }
      let(:consent) do
        create(
          :consent,
          :recorded,
          recorded_at: Date.new(2021, 1, 1),
          programme: session.programme
        )
      end

      it "calls template_mail with correct survey_deadline_date" do
        expect(
          mail.message.header["personalisation"].unparsed_value
        ).to include(survey_deadline_date: "8 January 2021")
      end
    end
  end
end
