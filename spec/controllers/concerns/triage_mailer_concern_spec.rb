require "rails_helper"

RSpec.describe TriageMailerConcern do
  let(:sample_class) { Class.new { include TriageMailerConcern }.new }

  describe "#send_triage_mail" do
    let(:patient_session) { nil }
    let(:consent) { nil }
    let(:mail) { double(deliver_later: true) }

    before do
      allow(ConsentFormMailer).to receive_messages(
        confirmation: mail,
        confirmation_needs_triage: mail,
        confirmation_injection: mail,
        confirmation_refused: mail,
        give_feedback: mail
      )
      allow(TriageMailer).to receive_messages(
        vaccination_will_happen: mail,
        vaccination_wont_happen: mail
      )
    end

    context "while doing triage" do
      before { sample_class.send_triage_mail(patient_session) }

      context "when the parents agree, triage is required and it is safe to vaccinate" do
        let(:patient_session) do
          build(:patient_session, :triaged_ready_to_vaccinate)
        end

        it "sends an email saying triage was needed and vaccination will happen" do
          expect(TriageMailer).to have_received(:vaccination_will_happen).with(
            patient_session
          )
        end
      end

      context "when the parents agree, triage is required but it isn't safe to vaccinate" do
        let(:patient_session) do
          build(:patient_session, :triaged_do_not_vaccinate)
        end

        it "sends an email saying triage was needed but vaccination won't happen" do
          expect(TriageMailer).to have_received(:vaccination_wont_happen).with(
            patient_session
          )
        end
      end

      context "when the parents agree and triage is not required" do
        let(:patient_session) do
          build(:patient_session, :consent_given_triage_not_needed)
        end

        it "doesn't send an email" do
          expect(ConsentFormMailer).not_to have_received(:confirmation).with(
            consent
          )
        end
      end

      context "when the parents agree, triage is required and a decision hasn't been made" do
        let(:patient_session) do
          build(:patient_session, :consent_given_triage_needed)
        end

        it "doesn't send an email" do
          expect(ConsentFormMailer).not_to have_received(
            :confirmation_needs_triage
          )
        end
      end

      context "when the parents have verbally refused consent" do
        let(:patient_session) { build(:patient_session, :consent_refused) }

        it "doesn't send an email" do
          expect(ConsentFormMailer).not_to have_received(:confirmation_refused)
        end
      end
    end

    context "while doing verbal consent" do
      before { sample_class.send_triage_mail(patient_session, consent) }

      context "when the parents agree, triage is required and it is safe to vaccinate" do
        let(:patient_session) do
          build(:patient_session, :triaged_ready_to_vaccinate)
        end
        let(:consent) { patient_session.consents.first }

        it "sends an email saying triage was needed and vaccination will happen" do
          expect(TriageMailer).to have_received(:vaccination_will_happen).with(
            patient_session
          )
        end
      end

      context "when the parents agree, triage is required but it isn't safe to vaccinate" do
        let(:patient_session) do
          build(:patient_session, :triaged_do_not_vaccinate)
        end
        let(:consent) { patient_session.consents.first }

        it "sends an email saying triage was needed but vaccination won't happen" do
          expect(TriageMailer).to have_received(:vaccination_wont_happen).with(
            patient_session
          )
        end
      end

      context "when the parents agree and triage is not required" do
        let(:patient_session) do
          build(:patient_session, :consent_given_triage_not_needed)
        end
        let(:consent) { patient_session.consents.first }

        it "sends an email saying vaccination will happen" do
          expect(ConsentFormMailer).to have_received(:confirmation).with(
            consent:,
            session: patient_session.session
          )
        end
      end

      context "when the parents agree, triage is required and a decision hasn't been made" do
        let(:patient_session) do
          build(:patient_session, :consent_given_triage_needed)
        end
        let(:consent) { patient_session.consents.first }

        it "sends an email saying triage is required" do
          expect(ConsentFormMailer).to have_received(
            :confirmation_needs_triage
          ).with(consent:, session: patient_session.session)
        end
      end

      context "when the parents have verbally refused consent" do
        let(:patient_session) { build(:patient_session, :consent_refused) }
        let(:consent) { patient_session.consents.first }

        it "sends an email confirming they've refused consent" do
          expect(ConsentFormMailer).to have_received(
            :confirmation_refused
          ).with(consent:, session: patient_session.session)
        end
      end
    end
  end
end
