# frozen_string_literal: true

describe ConsentRemindersJob do
  subject(:perform_now) { described_class.perform_now }

  before { Flipper.enable(:scheduled_emails) }
  after { Flipper.disable(:scheduled_emails) }

  let(:programme) { create(:programme) }

  let(:parents) { create_list(:parent, 2) }

  let(:patient_with_reminder_sent) do
    create(:patient, :consent_request_sent, :consent_reminder_sent, programme:)
  end
  let(:patient_not_sent_reminder) do
    create(:patient, :consent_request_sent, parents:, programme:)
  end
  let(:patient_not_sent_request) { create(:patient, parents:, programme:) }
  let(:patient_with_consent) do
    create(:patient, :consent_given_triage_not_needed, programme:)
  end

  let!(:patients) do
    [
      patient_with_reminder_sent,
      patient_not_sent_reminder,
      patient_not_sent_request,
      patient_with_consent
    ]
  end

  context "when session is unscheduled" do
    let(:session) { create(:session, :unscheduled, patients:, programme:) }

    it "doesn't send any notifications" do
      expect(ConsentNotification).not_to receive(:create_and_send!)
      perform_now
    end
  end

  context "when session is in the future" do
    let(:session) do
      create(
        :session,
        patients:,
        programme:,
        send_consent_requests_at: 2.days.from_now,
        days_before_first_consent_reminder: 7
      )
    end

    it "doesn't send any notifications" do
      expect(ConsentNotification).not_to receive(:create_and_send!)
      perform_now
    end
  end

  context "when the session is today" do
    let(:session) do
      create(
        :session,
        patients:,
        programme:,
        send_consent_requests_at: 7.days.ago,
        days_before_first_consent_reminder: 7
      )
    end

    it "sends notifications to one patient" do
      expect(ConsentNotification).to receive(:create_and_send!).once.with(
        patient: patient_not_sent_reminder,
        programme:,
        session:,
        reminder: true
      )
      perform_now
    end

    context "with a reminder sent a week ago" do
      before do
        create(
          :consent_notification,
          :reminder,
          programme:,
          patient: patient_with_consent,
          sent_at: 7.days.ago
        )
      end

      it "sends another notification to the patient" do
        expect(ConsentNotification).to receive(:create_and_send!).once.with(
          patient: patient_not_sent_reminder,
          programme:,
          session:,
          reminder: true
        )
        perform_now
      end
    end

    context "when maximum reminders already sent" do
      before do
        create_list(
          :consent_notification,
          4,
          :reminder,
          programme:,
          patient: patient_not_sent_reminder
        )
      end

      it "doesn't send any notifications" do
        expect(ConsentNotification).not_to receive(:create_and_send!)
        perform_now
      end
    end
  end
end
