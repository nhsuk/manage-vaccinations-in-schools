# frozen_string_literal: true

require "rails_helper"

describe VaccinationMailerConcern do
  let(:sample) { Class.new { include VaccinationMailerConcern }.new }

  describe "#send_vaccination_mail" do
    let(:route) { "website" }
    let(:consent) { create(:consent, route:) }
    let(:patient) { create(:patient, consents: [consent]) }
    let(:patient_session) { create(:patient_session, patient:) }
    let(:vaccination_record) do
      create(:vaccination_record, patient_session:, administered:)
    end
    let(:administered_mail) { double(deliver_later: true) }
    let(:not_administered_mail) { double(deliver_later: true) }

    before do
      allow(VaccinationMailer).to receive_messages(
        hpv_vaccination_has_taken_place: administered_mail,
        hpv_vaccination_has_not_taken_place: not_administered_mail
      )

      sample.send_vaccination_mail(vaccination_record)
    end

    context "when the vaccination has taken place" do
      let(:administered) { true }

      it "calls hpv_vaccination_has_taken_place" do
        expect(VaccinationMailer).to have_received(
          :hpv_vaccination_has_taken_place
        ).with(vaccination_record:)
      end

      it "delivers the email immediately" do
        expect(administered_mail).to have_received(:deliver_later)
      end
    end

    context "when the vaccination hasn't taken place" do
      let(:administered) { false }

      it "calls hpv_vaccination_has_not_taken_place" do
        expect(VaccinationMailer).to have_received(
          :hpv_vaccination_has_not_taken_place
        ).with(vaccination_record:)
      end

      it "delivers the email immediately" do
        expect(not_administered_mail).to have_received(:deliver_later)
      end
    end

    context "when the consent was done through gillick assessment" do
      let(:route) { "self_consent" }
      let(:vaccination_record) { create(:vaccination_record, patient_session:) }

      it "does not send an email" do
        expect(VaccinationMailer).not_to have_received(
          :hpv_vaccination_has_taken_place
        )
      end
    end
  end
end
