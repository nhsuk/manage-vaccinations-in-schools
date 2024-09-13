# frozen_string_literal: true

describe VaccinationMailerConcern do
  let(:sample) { Class.new { include VaccinationMailerConcern }.new }

  describe "#send_vaccination_mail" do
    subject(:send_vaccination_mail) do
      sample.send_vaccination_mail(vaccination_record)
    end

    let(:route) { "website" }
    let(:programme) { create(:programme, :active) }
    let(:session) { create(:session, programme:) }
    let(:consent) { create(:consent, programme:, route:) }
    let(:patient) { create(:patient, consents: [consent]) }
    let(:patient_session) { create(:patient_session, session:, patient:) }
    let(:vaccination_record) { create(:vaccination_record, patient_session:) }

    context "when the vaccination has taken place" do
      it "calls hpv_vaccination_has_taken_place" do
        expect { send_vaccination_mail }.to have_enqueued_mail(
          VaccinationMailer,
          :hpv_vaccination_has_taken_place
        ).with(params: { consent:, vaccination_record: }, args: [])
      end
    end

    context "when the vaccination hasn't taken place" do
      let(:vaccination_record) do
        create(:vaccination_record, :not_administered, patient_session:)
      end

      it "calls hpv_vaccination_has_not_taken_place" do
        expect { send_vaccination_mail }.to have_enqueued_mail(
          VaccinationMailer,
          :hpv_vaccination_has_not_taken_place
        ).with(params: { consent:, vaccination_record: }, args: [])
      end
    end

    context "when the consent was done through gillick assessment" do
      let(:route) { "self_consent" }
      let(:vaccination_record) { create(:vaccination_record, patient_session:) }

      it "does not send an email" do
        expect { send_vaccination_mail }.not_to have_enqueued_mail
      end
    end
  end
end
