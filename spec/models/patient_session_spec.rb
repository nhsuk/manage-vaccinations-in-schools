require "rails_helper"

RSpec.describe PatientSession do
  let(:patient_session_trait) { nil }
  let(:patient_session) { create :patient_session, patient_session_trait }

  describe "#ready_to_vaccinate?" do
    subject { patient_session.ready_to_vaccinate? }

    context "no consent response received yet" do
      let(:patient_session_trait) { :added_to_session }

      it { should be_falsey }
    end

    context "consent has been refused" do
      let(:patient_session_trait) { :consent_refused }

      it { should be_falsey }
    end

    context "consent has been given and triage is not needed" do
      let(:patient_session_trait) { :consent_given_triage_not_needed }

      it { should be_truthy }
    end

    context "consent has been given and triage is ready to vaccinate" do
      let(:patient_session_trait) { :triaged_ready_to_vaccinate }

      it { should be_truthy }
    end

    context "consent has been given and triage is do not vaccinate" do
      let(:patient_session_trait) { :triaged_do_not_vaccinate }

      it { should be_falsey }
    end

    context "patient was unable to be vaccinated" do
      let(:patient_session_trait) { :unable_to_vaccinate }

      it { should be_falsey }
    end

    context "patient has been vaccinated" do
      let(:patient_session_trait) { :vaccinated }

      it { should be_falsey }
    end
  end
end
