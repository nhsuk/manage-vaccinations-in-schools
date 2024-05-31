require "rails_helper"

RSpec.describe TriageMailer, type: :mailer do
  describe "#vaccination_will_happen" do
    let(:patient_session) do
      create(:patient_session, :consent_given_triage_not_needed)
    end
    let(:consent) { patient_session.patient.consents.first }

    subject(:mail) { TriageMailer.vaccination_will_happen(patient_session) }

    it { should have_attributes(to: [consent.parent_email]) }

    describe "personalisation" do
      subject { mail.message.header["personalisation"].unparsed_value }

      it { should include(parent_name: consent.parent_name) }
    end
  end

  describe "#vaccination_wont_happen" do
    let(:patient_session) { create(:patient_session, :consent_refused) }
    let(:consent) { patient_session.patient.consents.first }

    subject(:mail) { TriageMailer.vaccination_wont_happen(patient_session) }

    it { should have_attributes(to: [consent.parent_email]) }

    describe "personalisation" do
      subject { mail.message.header["personalisation"].unparsed_value }

      it { should include(parent_name: consent.parent_name) }
    end
  end
end
