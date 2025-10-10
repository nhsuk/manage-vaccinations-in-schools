# frozen_string_literal: true

describe AlreadyHadNotificationSender do
  describe "#call" do
    subject(:call) { described_class.call(vaccination_record:) }

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
        expect { call }.not_to have_delivered_email
      end

      it "returns early without sending sms notifications" do
        expect { call }.not_to have_delivered_sms
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
          expect { call }.not_to have_delivered_email
        end

        it "returns early without sending sms notifications" do
          expect { call }.not_to have_delivered_sms
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

        it "sends email notifications to all parents with valid consents" do
          call

          expect(EmailDeliveryJob).to have_been_enqueued.with(
            :vaccination_already_had,
            parent: first_parent,
            vaccination_record:,
            consent: first_consent
          )

          expect(EmailDeliveryJob).to have_been_enqueued.with(
            :vaccination_already_had,
            parent: second_parent,
            vaccination_record:,
            consent: second_consent
          )
        end

        it "sends SMS notifications only to parents who opted in for updates" do
          call

          expect(SMSDeliveryJob).to have_been_enqueued.with(
            :vaccination_already_had,
            parent: first_parent,
            vaccination_record:,
            consent: first_consent
          )

          expect(SMSDeliveryJob).not_to have_been_enqueued.with(
            :vaccination_already_had,
            parent: second_parent,
            vaccination_record:,
            consent: second_consent
          )
        end

        it "updates consents with patient_already_vaccinated_notification_sent_at" do
          expect(
            first_consent.patient_already_vaccinated_notification_sent_at
          ).to be_nil
          expect(
            second_consent.patient_already_vaccinated_notification_sent_at
          ).to be_nil

          call

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
            call

            expect(EmailDeliveryJob).not_to have_been_enqueued.with(
              :vaccination_already_had,
              parent: first_parent,
              vaccination_record:,
              consent: first_consent
            )

            expect(EmailDeliveryJob).to have_been_enqueued.with(
              :vaccination_already_had,
              parent: second_parent,
              vaccination_record:,
              consent: second_consent
            )
          end
        end

        context "with withdrawn consents" do
          let!(:first_consent) do
            create(
              :consent,
              :withdrawn,
              patient:,
              programme:,
              parent: first_parent,
              academic_year:
            )
          end

          it "ignores withdrawn consents" do
            call

            expect(EmailDeliveryJob).not_to have_been_enqueued.with(
              :vaccination_already_had,
              parent: first_parent,
              vaccination_record:,
              consent: first_consent
            )

            expect(EmailDeliveryJob).to have_been_enqueued.with(
              :vaccination_already_had,
              parent: second_parent,
              vaccination_record:,
              consent: second_consent
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
            call

            expect(EmailDeliveryJob).not_to have_been_enqueued.with(
              :vaccination_already_had,
              parent: first_parent,
              vaccination_record:,
              consent: first_consent
            )

            expect(EmailDeliveryJob).to have_been_enqueued.with(
              :vaccination_already_had,
              parent: second_parent,
              vaccination_record:,
              consent: second_consent
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
            call

            expect(EmailDeliveryJob).to have_been_enqueued.with(
              :vaccination_already_had,
              parent: first_parent,
              vaccination_record:,
              consent: first_consent
            )

            expect(EmailDeliveryJob).to have_been_enqueued.with(
              :vaccination_already_had,
              parent: second_parent,
              vaccination_record:,
              consent: second_consent
            )
          end
        end
      end

      context "when no valid consents exist" do
        it "does not send any emails" do
          expect { call }.not_to have_delivered_email
        end

        it "does not send any sms" do
          expect { call }.not_to have_delivered_sms
        end
      end
    end
  end
end
