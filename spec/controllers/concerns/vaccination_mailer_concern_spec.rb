# frozen_string_literal: true

describe VaccinationMailerConcern do
  before do
    stub_const("SampleClass", Class.new).class_eval do
      include VaccinationMailerConcern # rubocop:disable RSpec/DescribedClass

      attr_reader :current_user

      def initialize(current_user:)
        @current_user = current_user
      end
    end
  end

  let(:sample) { SampleClass.new(current_user:) }
  let(:current_user) { create(:user) }

  describe "#send_vaccination_confirmation" do
    subject(:send_vaccination_confirmation) do
      sample.send_vaccination_confirmation(vaccination_record)
    end

    let(:programme) { create(:programme) }
    let(:session) { create(:session, programme:) }
    let(:consent) { create(:consent, :given, :recorded, programme:) }
    let(:parent) { consent.parent }
    let(:patient) { create(:patient, consents: [consent]) }
    let(:patient_session) { create(:patient_session, session:, patient:) }
    let(:vaccination_record) do
      create(:vaccination_record, programme:, patient_session:)
    end

    context "when the vaccination has taken place" do
      it "sends an email" do
        expect { send_vaccination_confirmation }.to have_enqueued_mail(
          VaccinationMailer,
          :confirmation_administered
        ).with(
          params: {
            parent:,
            patient:,
            vaccination_record:,
            sent_by: current_user
          },
          args: []
        )
      end

      it "sends a text message" do
        expect { send_vaccination_confirmation }.to have_enqueued_text(
          :vaccination_confirmation_administered
        ).with(parent:, patient:, vaccination_record:, sent_by: current_user)
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
          :confirmation_not_administered
        ).with(
          params: {
            parent:,
            patient:,
            vaccination_record:,
            sent_by: current_user
          },
          args: []
        )
      end

      it "sends a text message" do
        expect { send_vaccination_confirmation }.to have_enqueued_text(
          :vaccination_confirmation_not_administered
        ).with(parent:, patient:, vaccination_record:, sent_by: current_user)
      end
    end

    context "when the consent was done through gillick assessment" do
      let(:consent) do
        create(:consent, :given, :recorded, :self_consent, programme:)
      end

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

    context "if the patient is deceased" do
      let(:patient) { create(:patient, :deceased) }

      it "doesn't send an email" do
        expect { send_vaccination_confirmation }.not_to have_enqueued_email
      end

      it "doesn't send a text message" do
        expect { send_vaccination_confirmation }.not_to have_enqueued_text
      end
    end

    context "if the patient is invalid" do
      let(:patient) { create(:patient, :invalidated) }

      it "doesn't send an email" do
        expect { send_vaccination_confirmation }.not_to have_enqueued_email
      end

      it "doesn't send a text message" do
        expect { send_vaccination_confirmation }.not_to have_enqueued_text
      end
    end

    context "if the patient is restricted" do
      let(:patient) { create(:patient, :restricted) }

      it "doesn't send an email" do
        expect { send_vaccination_confirmation }.not_to have_enqueued_email
      end

      it "doesn't send a text message" do
        expect { send_vaccination_confirmation }.not_to have_enqueued_text
      end
    end
  end
end
