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
        create(
          :vaccination_record,
          programme:,
          patient:,
          session:,
          notify_parents:
        )
      end

      context "when child wants parents to be notified" do
        let(:notify_parents) { true }

        before do
          create(
            :consent,
            :given,
            :self_consent,
            :notify_parents_on_vaccination,
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

        let(:notify_parents) { false }

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

  describe "#send_vaccination_discovered_if_required" do
    subject(:send_vaccination_discovered_if_required) do
      sample.send_vaccination_discovered_if_required(vaccination_record)
    end

    let(:programme) { create(:programme) }
    let(:academic_year) { AcademicYear.current }
    let(:session) do
      create(:session, :scheduled, programmes: [programme], academic_year:)
    end
    let(:first_parent) { create(:parent, phone_receive_updates: true) }
    let(:second_parent) { create(:parent, phone_receive_updates: false) }
    let(:patient) do
      create(:patient, parents: [first_parent, second_parent], session:)
    end
    let(:vaccination_record) do
      create(:vaccination_record, programme:, patient:, session:)
    end

    before { ActiveJob::Base.queue_adapter.enqueued_jobs.clear }

    context "when vaccination record is sourced from service and not already had" do
      before do
        allow(vaccination_record).to receive_messages(
          sourced_from_service?: true,
          already_had?: false
        )
      end

      it "returns early without sending email notifications" do
        expect {
          send_vaccination_discovered_if_required
        }.not_to have_delivered_email
      end

      it "returns early without sending sms notifications" do
        expect {
          send_vaccination_discovered_if_required
        }.not_to have_delivered_sms
      end
    end

    context "when vaccination record is not sourced from service" do
      before do
        allow(vaccination_record).to receive_messages(
          sourced_from_service?: false,
          already_had?: false
        )
      end

      context "when patient is already considered vaccinated" do
        before { create(:vaccination_record, programme:, patient:, session:) }

        it "returns early without sending email notifications" do
          expect {
            send_vaccination_discovered_if_required
          }.not_to have_delivered_email
        end

        it "returns early without sending sms notifications" do
          expect {
            send_vaccination_discovered_if_required
          }.not_to have_delivered_sms
        end
      end

      context "when patient is not considered vaccinated and has valid consents" do
        let!(:first_consent) do
          create(
            :consent,
            :given,
            patient:,
            programme:,
            parent: first_parent,
            academic_year:
          )
        end
        let!(:second_consent) do
          create(
            :consent,
            :given,
            patient:,
            programme:,
            parent: second_parent,
            academic_year:
          )
        end

        before { allow(VaccinatedCriteria).to receive(:call).and_return(false) }

        it "sends email notifications to all parents with valid consents" do
          send_vaccination_discovered_if_required

          expect(EmailDeliveryJob).to have_been_enqueued.with(
            :vaccination_discovered,
            parent: first_parent,
            vaccination_record:
          )

          expect(EmailDeliveryJob).to have_been_enqueued.with(
            :vaccination_discovered,
            parent: second_parent,
            vaccination_record:
          )
        end

        it "sends SMS notifications only to parents who opted in for updates" do
          send_vaccination_discovered_if_required

          expect(SMSDeliveryJob).to have_been_enqueued.with(
            :vaccination_discovered,
            parent: first_parent,
            vaccination_record:
          )

          expect(SMSDeliveryJob).not_to have_been_enqueued.with(
            :vaccination_discovered,
            parent: second_parent,
            vaccination_record:
          )
        end

        it "updates consents with patient_already_vaccinated_notification_sent_at" do
          expect(
            first_consent.patient_already_vaccinated_notification_sent_at
          ).to be_nil
          expect(
            second_consent.patient_already_vaccinated_notification_sent_at
          ).to be_nil

          send_vaccination_discovered_if_required

          expect(
            first_consent.reload.patient_already_vaccinated_notification_sent_at
          ).to be_present
          expect(
            second_consent.reload.patient_already_vaccinated_notification_sent_at
          ).to be_present
        end

        context "with invalidated consents" do
          before do
            first_consent.update!(
              invalidated_at: 1.day.ago,
              notes: "Some notes"
            )
          end

          it "ignores invalidated consents" do
            send_vaccination_discovered_if_required

            expect(EmailDeliveryJob).not_to have_been_enqueued.with(
              :vaccination_discovered,
              parent: first_parent,
              vaccination_record:
            )

            expect(EmailDeliveryJob).to have_been_enqueued.with(
              :vaccination_discovered,
              parent: second_parent,
              vaccination_record:
            )
          end
        end

        context "with withdrawn consents" do
          before do
            first_consent.update!(
              withdrawn_at: 1.day.ago,
              notes: "Some notes",
              reason_for_refusal: "personal_choice"
            )
          end

          it "ignores withdrawn consents" do
            send_vaccination_discovered_if_required

            expect(EmailDeliveryJob).not_to have_been_enqueued.with(
              :vaccination_discovered,
              parent: first_parent,
              vaccination_record:
            )

            expect(EmailDeliveryJob).to have_been_enqueued.with(
              :vaccination_discovered,
              parent: second_parent,
              vaccination_record:
            )
          end
        end

        context "with consents already notified after this vaccination record was created" do
          before do
            first_consent.update!(
              patient_already_vaccinated_notification_sent_at:
                vaccination_record.created_at + 1.hour
            )
          end

          it "includes only consents not yet notified or notified before this vaccination record" do
            send_vaccination_discovered_if_required

            expect(EmailDeliveryJob).not_to have_been_enqueued.with(
              :vaccination_discovered,
              parent: first_parent,
              vaccination_record:
            )

            expect(EmailDeliveryJob).to have_been_enqueued.with(
              :vaccination_discovered,
              parent: second_parent,
              vaccination_record:
            )
          end
        end

        context "with consents notified before this vaccination record was created" do
          before do
            first_consent.update!(
              patient_already_vaccinated_notification_sent_at:
                vaccination_record.created_at - 1.hour
            )
          end

          it "includes consents notified before this vaccination record" do
            send_vaccination_discovered_if_required

            expect(EmailDeliveryJob).to have_been_enqueued.with(
              :vaccination_discovered,
              parent: first_parent,
              vaccination_record:
            )

            expect(EmailDeliveryJob).to have_been_enqueued.with(
              :vaccination_discovered,
              parent: second_parent,
              vaccination_record:
            )
          end
        end
      end

      context "when no valid consents exist" do
        it "does not send any emails" do
          expect {
            send_vaccination_discovered_if_required
          }.not_to have_delivered_email
        end

        it "does not send any sms" do
          expect {
            send_vaccination_discovered_if_required
          }.not_to have_delivered_sms
        end
      end
    end
  end
end
