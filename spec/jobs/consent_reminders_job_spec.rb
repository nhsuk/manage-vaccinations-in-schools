# frozen_string_literal: true

describe ConsentRemindersJob do
  subject(:perform_now) { described_class.perform_now }

  before { Flipper.enable(:scheduled_emails) }
  after { Flipper.disable(:scheduled_emails) }

  let(:programme) { create(:programme) }

  let(:parents) { create_list(:parent, 2) }

  let(:patient_with_initial_reminder_sent) do
    create(
      :patient,
      :consent_request_sent,
      :initial_consent_reminder_sent,
      programme:
    )
  end
  let(:patient_not_sent_reminder) do
    create(:patient, :consent_request_sent, parents:, programme:)
  end
  let(:patient_not_sent_request) { create(:patient, parents:, programme:) }
  let(:patient_with_consent) do
    create(:patient, :consent_given_triage_not_needed, programme:)
  end
  let(:deceased_patient) { create(:patient, :deceased) }
  let(:invalid_patient) { create(:patient, :invalidated) }
  let(:restricted_patient) { create(:patient, :restricted) }

  let!(:patients) do
    [
      patient_with_initial_reminder_sent,
      patient_not_sent_reminder,
      patient_not_sent_request,
      patient_with_consent,
      deceased_patient,
      invalid_patient,
      restricted_patient
    ]
  end

  let(:dates) { [Date.new(2024, 1, 12), Date.new(2024, 1, 15)] }

  let!(:session) do
    create(
      :session,
      date: nil,
      dates: dates.map { build(:session_date, value: _1) },
      patients:,
      programme:,
      days_before_consent_reminders: 7
    )
  end

  around { |example| travel_to(today) { example.run } }

  context "two weeks before the first session" do
    let(:today) { dates.first - 2.weeks }

    it "doesn't send any notifications" do
      expect(ConsentNotification).not_to receive(:create_and_send!)
      perform_now
    end
  end

  context "one week before the first session" do
    let(:today) { dates.first - 1.week }

    it "sends notifications to one patient" do
      expect(ConsentNotification).to receive(:create_and_send!).once.with(
        patient: patient_not_sent_reminder,
        programme:,
        session:,
        type: :initial_reminder
      )
      perform_now
    end

    it "records a notification" do
      expect { perform_now }.to change(ConsentNotification, :count).by(1)
    end
  end

  context "six days before the first session with reminders already sent" do
    let(:today) { dates.first - 6.days }

    before do
      create(
        :consent_notification,
        :initial_reminder,
        patient: patient_not_sent_reminder,
        programme:
      )
    end

    it "doesn't send any notifications" do
      expect(ConsentNotification).not_to receive(:create_and_send!)
      perform_now
    end
  end

  context "one week before the second session" do
    let(:today) { dates.last - 1.week }

    it "sends notifications to two patients" do
      expect(ConsentNotification).to receive(:create_and_send!).once.with(
        patient: patient_not_sent_reminder,
        programme:,
        session:,
        type: :initial_reminder
      )

      expect(ConsentNotification).to receive(:create_and_send!).once.with(
        patient: patient_with_initial_reminder_sent,
        programme:,
        session:,
        type: :subsequent_reminder
      )

      perform_now
    end

    it "records the notifications" do
      expect { perform_now }.to change(ConsentNotification, :count).by(2)
    end
  end
end
