# frozen_string_literal: true

describe TriageMailer do
  let(:session) { patient_session.session }

  describe "#vaccination_will_happen" do
    subject(:mail) do
      described_class.with(consent:, session:).vaccination_will_happen
    end

    let(:patient_session) do
      create(:patient_session, :consent_given_triage_not_needed)
    end
    let(:consent) { patient_session.patient.consents.first }

    it { should have_attributes(to: [consent.parent.email]) }

    describe "personalisation" do
      subject { mail.message.header["personalisation"].unparsed_value }

      it { should include(parent_full_name: consent.parent.full_name) }
    end
  end

  describe "#vaccination_wont_happen" do
    subject(:mail) do
      described_class.with(consent:, session:).vaccination_wont_happen
    end

    let(:patient_session) { create(:patient_session, :consent_refused) }
    let(:consent) { patient_session.patient.consents.first }

    it { should have_attributes(to: [consent.parent.email]) }

    describe "personalisation" do
      subject { mail.message.header["personalisation"].unparsed_value }

      it { should include(parent_full_name: consent.parent.full_name) }
    end
  end
end
