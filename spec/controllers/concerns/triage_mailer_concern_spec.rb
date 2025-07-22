# frozen_string_literal: true

describe TriageMailerConcern do
  before do
    stub_const("SampleClass", Class.new).class_eval do
      include TriageMailerConcern # rubocop:disable RSpec/DescribedClass

      attr_reader :current_user

      def initialize(current_user:)
        @current_user = current_user
      end
    end

    patient_session.strict_loading!(false)
  end

  let(:sample) { SampleClass.new(current_user:) }
  let(:current_user) { create(:user) }

  let(:programme) { create(:programme) }
  let(:programmes) { [programme] }
  let(:patient) { patient_session.patient }

  describe "#send_triage_confirmation" do
    subject(:send_triage_confirmation) do
      sample.send_triage_confirmation(patient_session, programme, consent)
    end

    let(:session) { create(:session, programmes:) }
    let(:consent) { patient.consents.first }

    context "when the parents agree, triage is required and it is safe to vaccinate" do
      let(:patient_session) do
        create(:patient_session, :triaged_ready_to_vaccinate, session:)
      end

      it "sends an email saying triage was needed and vaccination will happen" do
        expect { send_triage_confirmation }.to have_delivered_email(
          :triage_vaccination_will_happen
        ).with(consent:, session:, sent_by: current_user)
      end

      it "doesn't send a text message" do
        expect { send_triage_confirmation }.not_to have_delivered_sms
      end
    end

    context "when the parents agree, triage is required but it isn't safe to vaccinate" do
      let(:patient_session) do
        create(:patient_session, :triaged_do_not_vaccinate, session:)
      end

      it "sends an email saying triage was needed but vaccination won't happen" do
        expect { send_triage_confirmation }.to have_delivered_email(
          :triage_vaccination_wont_happen
        ).with(consent:, session:, sent_by: current_user)
      end

      it "doesn't send a text message" do
        expect { send_triage_confirmation }.not_to have_delivered_sms
      end
    end

    context "when the parents agree, triage is required and vaccination should be delayed" do
      let(:patient_session) do
        create(:patient_session, :delay_vaccination, session:)
      end

      it "sends an email saying triage was needed but vaccination won't happen" do
        expect { send_triage_confirmation }.to have_delivered_email(
          :triage_vaccination_at_clinic
        ).with(consent:, session:, sent_by: current_user)
      end

      it "doesn't send a text message" do
        expect { send_triage_confirmation }.not_to have_delivered_sms
      end

      context "when the team is Coventry & Warwickshire Partnership NHS Trust (CWPT)" do
        let(:session) { create(:session, programmes: [programme], team:) }
        let(:team) { create(:team, ods_code: "RYG") }

        it "enqueues an email using the CWPT-specific template" do
          expect { send_triage_confirmation }.to have_delivered_email(
            :triage_vaccination_at_clinic_ryg
          ).with(consent:, session:, sent_by: current_user)
        end
      end
    end

    context "when the parents agree and triage is not required" do
      let(:patient_session) do
        create(:patient_session, :consent_given_triage_not_needed, session:)
      end

      it "sends an email saying vaccination will happen" do
        expect { send_triage_confirmation }.to have_delivered_email(
          :consent_confirmation_given
        ).with(consent:, session:, sent_by: current_user)
      end

      it "sends a text message" do
        expect { send_triage_confirmation }.to have_delivered_sms(
          :consent_confirmation_given
        ).with(consent:, session:, sent_by: current_user)
      end
    end

    context "when the parents agree, triage is required and a decision hasn't been made" do
      let(:patient_session) do
        create(:patient_session, :consent_given_triage_needed, session:)
      end

      it "sends an email saying triage is required" do
        expect { send_triage_confirmation }.to have_delivered_email(
          :consent_confirmation_triage
        ).with(consent:, session:, sent_by: current_user)
      end

      it "doesn't send a text message" do
        expect { send_triage_confirmation }.not_to have_delivered_sms
      end
    end

    context "when the patient didn't response" do
      let(:patient_session) do
        create(:patient_session, :consent_not_provided, session:)
      end

      it "doesn't send an email" do
        expect { send_triage_confirmation }.not_to have_delivered_email
      end

      it "doesn't send a text message" do
        expect { send_triage_confirmation }.not_to have_delivered_sms
      end
    end

    context "when the patient self-consented" do
      let(:patient_session) { create(:patient_session, session:) }
      let(:consent) do
        create(
          :consent,
          :self_consent,
          :given,
          patient: patient_session.patient,
          programme:
        )
      end

      it "doesn't send an email" do
        expect { send_triage_confirmation }.not_to have_delivered_email
      end

      it "doesn't send a text message" do
        expect { send_triage_confirmation }.not_to have_delivered_sms
      end
    end

    context "when the parents have verbally refused consent" do
      let(:patient_session) do
        create(:patient_session, :consent_refused, session:)
      end

      it "sends an email confirming they've refused consent" do
        expect { send_triage_confirmation }.to have_delivered_email(
          :consent_confirmation_refused
        ).with(consent:, session:, sent_by: current_user)
      end

      it "sends a text message" do
        expect { send_triage_confirmation }.to have_delivered_sms(
          :consent_confirmation_refused
        ).with(consent:, session:, sent_by: current_user)
      end
    end

    context "if the patient is deceased" do
      let(:patient) do
        create(
          :patient,
          :consent_given_triage_not_needed,
          :deceased,
          programmes:
        )
      end
      let(:patient_session) { create(:patient_session, patient:, session:) }

      it "doesn't send an email" do
        expect { send_triage_confirmation }.not_to have_delivered_email
      end

      it "doesn't send a text message" do
        expect { send_triage_confirmation }.not_to have_delivered_sms
      end
    end

    context "if the patient is invalid" do
      let(:patient) do
        create(
          :patient,
          :consent_given_triage_not_needed,
          :invalidated,
          programmes:
        )
      end
      let(:patient_session) { create(:patient_session, patient:, session:) }

      it "doesn't send an email" do
        expect { send_triage_confirmation }.not_to have_delivered_email
      end

      it "doesn't send a text message" do
        expect { send_triage_confirmation }.not_to have_delivered_sms
      end
    end

    context "if the patient is restricted" do
      let(:patient) do
        create(
          :patient,
          :consent_given_triage_not_needed,
          :restricted,
          programmes:
        )
      end
      let(:patient_session) { create(:patient_session, patient:, session:) }

      it "doesn't send an email" do
        expect { send_triage_confirmation }.not_to have_delivered_email
      end

      it "doesn't send a text message" do
        expect { send_triage_confirmation }.not_to have_delivered_sms
      end
    end
  end
end
