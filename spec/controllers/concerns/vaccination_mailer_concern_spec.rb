# frozen_string_literal: true

describe VaccinationMailerConcern do
  let(:sample) { Class.new { include VaccinationMailerConcern }.new }

  describe "#send_vaccination_confirmation" do
    subject(:send_vaccination_confirmation) do
      sample.send_vaccination_confirmation(vaccination_record)
    end

    let(:route) { "website" }
    let(:programme) { create(:programme) }
    let(:session) { create(:session, programme:) }
    let(:consent) { create(:consent, :given, :recorded, programme:, route:) }
    let(:patient) { create(:patient, consents: [consent]) }
    let(:patient_session) { create(:patient_session, session:, patient:) }
    let(:vaccination_record) do
      create(:vaccination_record, programme:, patient_session:)
    end

    context "when the vaccination has taken place" do
      it "sends an email" do
        expect { send_vaccination_confirmation }.to have_enqueued_mail(
          VaccinationMailer,
          :hpv_vaccination_has_taken_place
        ).with(params: { consent:, vaccination_record: }, args: [])
      end

      it "sends a text message" do
        expect { send_vaccination_confirmation }.to have_enqueued_text(
          :vaccination_has_taken_place
        ).with(consent:, vaccination_record:)
      end
    end

    context "when the vaccination hasn't taken place" do
      let(:vaccination_record) do
        create(
          :vaccination_record,
          :not_administered,
          programme:,
          patient_session:
        )
      end

      it "sends an email" do
        expect { send_vaccination_confirmation }.to have_enqueued_mail(
          VaccinationMailer,
          :hpv_vaccination_has_not_taken_place
        ).with(params: { consent:, vaccination_record: }, args: [])
      end

      it "sends a text message" do
        expect { send_vaccination_confirmation }.to have_enqueued_text(
          :vaccination_didnt_happen
        ).with(consent:, vaccination_record:)
      end
    end

    context "when the consent was done through gillick assessment" do
      let(:route) { "self_consent" }
      let(:vaccination_record) do
        create(:vaccination_record, programme:, patient_session:)
      end

      it "doesn't send an email" do
        expect { send_vaccination_confirmation }.not_to have_enqueued_mail
      end

      it "doesn't send a text message" do
        expect { send_vaccination_confirmation }.not_to have_enqueued_text
      end
    end
  end
end
