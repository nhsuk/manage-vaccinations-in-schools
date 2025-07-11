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

    vaccination_record.strict_loading!(false)
    vaccination_record.patient.strict_loading!(false)
  end

  let(:sample) { SampleClass.new(current_user:) }
  let(:current_user) { create(:user) }

  describe "#send_vaccination_confirmation" do
    subject(:send_vaccination_confirmation) do
      sample.send_vaccination_confirmation(vaccination_record)
    end

    let(:programme) { create(:programme, :hpv) }
    let(:session) { create(:session, programmes: [programme]) }
    let(:parent) { create(:parent) }
    let(:patient) { create(:patient, parents: [parent], session:) }
    let(:vaccination_record) do
      create(:vaccination_record, programme:, patient:, session:)
    end

    context "when the vaccination has taken place" do
      before { create(:consent, :given, patient:, programme:) }

      it "sends an email" do
        expect { send_vaccination_confirmation }.to have_delivered_email(
          :vaccination_administered_hpv
        ).with(parent:, vaccination_record:, sent_by: current_user)
      end

      it "sends a text message" do
        expect { send_vaccination_confirmation }.to have_delivered_sms(
          :vaccination_administered
        ).with(parent:, vaccination_record:, sent_by: current_user)
      end
    end

    context "when the vaccination hasn't taken place" do
      before { create(:consent, :given, patient:, programme:) }

      let(:vaccination_record) do
        create(
          :vaccination_record,
          :not_administered,
          programme:,
          patient:,
          session:
        )
      end

      it "sends an email" do
        expect { send_vaccination_confirmation }.to have_delivered_email(
          :vaccination_not_administered
        ).with(parent:, vaccination_record:, sent_by: current_user)
      end

      it "sends a text message" do
        expect { send_vaccination_confirmation }.to have_delivered_sms(
          :vaccination_not_administered
        ).with(parent:, vaccination_record:, sent_by: current_user)
      end
    end

    context "when the consent was done through gillick assessment" do
      let(:vaccination_record) do
        create(:vaccination_record, programme:, patient:, session:)
      end

      context "when child wants parents to be notified" do
        before do
          create(
            :consent,
            :given,
            :self_consent,
            :notify_parents,
            patient:,
            programme:
          )
        end

        it "sends an email" do
          expect { send_vaccination_confirmation }.to have_delivered_email(
            :vaccination_administered_hpv
          ).with(parent:, vaccination_record:, sent_by: current_user)
        end

        it "sends a text message" do
          expect { send_vaccination_confirmation }.to have_delivered_sms(
            :vaccination_administered
          ).with(parent:, vaccination_record:, sent_by: current_user)
        end
      end

      context "when child doesn't want a parent to be notified" do
        before { create(:consent, :given, :self_consent, patient:, programme:) }

        it "doesn't send an email" do
          expect { send_vaccination_confirmation }.not_to have_delivered_email
        end

        it "doesn't send a text message" do
          expect { send_vaccination_confirmation }.not_to have_delivered_sms
        end
      end
    end

    context "if the patient is deceased" do
      let(:patient) { create(:patient, :deceased) }

      it "doesn't send an email" do
        expect { send_vaccination_confirmation }.not_to have_delivered_email
      end

      it "doesn't send a text message" do
        expect { send_vaccination_confirmation }.not_to have_delivered_sms
      end
    end

    context "if the patient is invalid" do
      let(:patient) { create(:patient, :invalidated) }

      it "doesn't send an email" do
        expect { send_vaccination_confirmation }.not_to have_delivered_email
      end

      it "doesn't send a text message" do
        expect { send_vaccination_confirmation }.not_to have_delivered_sms
      end
    end

    context "if the patient is restricted" do
      let(:patient) { create(:patient, :restricted) }

      it "doesn't send an email" do
        expect { send_vaccination_confirmation }.not_to have_delivered_email
      end

      it "doesn't send a text message" do
        expect { send_vaccination_confirmation }.not_to have_delivered_sms
      end
    end
  end
end
