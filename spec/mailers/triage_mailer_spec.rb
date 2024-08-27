# frozen_string_literal: true

describe TriageMailer, type: :mailer do
  describe "#vaccination_will_happen" do
    subject(:mail) do
      described_class.vaccination_will_happen(patient_session, consent)
    end

    let(:patient_session) do
      create(:patient_session, :consent_given_triage_not_needed)
    end
    let(:consent) { patient_session.patient.consents.first }

    it { should have_attributes(to: [consent.parent.email]) }

    describe "personalisation" do
      subject { mail.message.header["personalisation"].unparsed_value }

      it { should include(parent_name: consent.parent.name) }
    end
  end

  describe "#vaccination_wont_happen" do
    subject(:mail) do
      described_class.vaccination_wont_happen(patient_session, consent)
    end

    let(:patient_session) { create(:patient_session, :consent_refused) }
    let(:consent) { patient_session.patient.consents.first }

    it { should have_attributes(to: [consent.parent.email]) }

    describe "personalisation" do
      subject { mail.message.header["personalisation"].unparsed_value }

      it { should include(parent_name: consent.parent.name) }
    end
  end
end
