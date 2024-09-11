# frozen_string_literal: true

describe TriageMailerConcern do
  let(:sample_class) { Class.new { include TriageMailerConcern }.new }

  describe "#send_triage_mail" do
    subject(:send_triage_mail) do
      sample_class.send_triage_mail(patient_session, consent)
    end

    let(:session) { patient_session.session }
    let(:consent) { patient_session.consents.first }

    context "when the parents agree, triage is required and it is safe to vaccinate" do
      let(:patient_session) do
        create(:patient_session, :triaged_ready_to_vaccinate)
      end

      it "sends an email saying triage was needed and vaccination will happen" do
        expect { send_triage_mail }.to have_enqueued_mail(
          TriageMailer,
          :vaccination_will_happen
        ).with(params: { consent:, session: }, args: [])
      end
    end

    context "when the parents agree, triage is required but it isn't safe to vaccinate" do
      let(:patient_session) do
        create(:patient_session, :triaged_do_not_vaccinate)
      end

      it "sends an email saying triage was needed but vaccination won't happen" do
        expect { send_triage_mail }.to have_enqueued_mail(
          TriageMailer,
          :vaccination_wont_happen
        ).with(params: { consent:, session: }, args: [])
      end
    end

    context "when the parents agree and triage is not required" do
      let(:patient_session) do
        create(:patient_session, :consent_given_triage_not_needed)
      end

      it "sends an email saying vaccination will happen" do
        expect { send_triage_mail }.to have_enqueued_mail(
          ConsentFormMailer,
          :confirmation
        ).with(params: { consent:, session: }, args: [])
      end
    end

    context "when the parents agree, triage is required and a decision hasn't been made" do
      let(:patient_session) do
        create(:patient_session, :consent_given_triage_needed)
      end

      it "sends an email saying triage is required" do
        expect { send_triage_mail }.to have_enqueued_mail(
          ConsentFormMailer,
          :confirmation_needs_triage
        ).with(params: { consent:, session: }, args: [])
      end
    end

    context "when the parents have verbally refused consent" do
      let(:patient_session) { create(:patient_session, :consent_refused) }

      it "sends an email confirming they've refused consent" do
        expect { send_triage_mail }.to have_enqueued_mail(
          ConsentFormMailer,
          :confirmation_refused
        ).with(params: { consent:, session: }, args: [])
      end
    end
  end
end
