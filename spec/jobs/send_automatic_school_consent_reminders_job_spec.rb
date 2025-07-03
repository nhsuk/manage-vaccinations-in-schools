# frozen_string_literal: true

describe SendAutomaticSchoolConsentRemindersJob do
  subject(:perform_now) { described_class.perform_now(session) }

  let(:programmes) { [create(:programme)] }

  let(:parents) { create_list(:parent, 2) }

  let(:patient_with_initial_reminder_sent) do
    create(
      :patient,
      :consent_request_sent,
      :initial_consent_reminder_sent,
      parents:,
      programmes:
    )
  end
  let(:patient_not_sent_reminder) do
    create(:patient, :consent_request_sent, parents:, programmes:)
  end
  let(:patient_not_sent_reminder_joined_after_first_date) do
    create(:patient, :consent_request_sent, parents:, programmes:)
  end
  let(:patient_not_sent_request) { create(:patient, parents:, programmes:) }
  let(:patient_with_consent) do
    create(:patient, :consent_given_triage_not_needed, programmes:)
  end
  let(:deceased_patient) { create(:patient, :deceased) }
  let(:invalid_patient) { create(:patient, :invalidated) }
  let(:restricted_patient) { create(:patient, :restricted) }

  let!(:patients) do
    [
      patient_with_initial_reminder_sent,
      patient_not_sent_reminder,
      patient_not_sent_reminder_joined_after_first_date,
      patient_not_sent_request,
      patient_with_consent,
      deceased_patient,
      invalid_patient,
      restricted_patient
    ]
  end

  let(:dates) { [Date.new(2024, 2, 1), Date.new(2024, 3, 1)] }

  let(:team) { create(:team, programmes:) }
  let(:location) { create(:school, team:) }

  let!(:session) do
    create(
      :session,
      dates:,
      send_consent_requests_at: dates.first - 3.weeks,
      days_before_consent_reminders: 7,
      location:,
      patients:,
      programmes:,
      team:
    )
  end

  before do
    ConsentNotification.request.update_all(sent_at: dates.first - 1.week)
    ConsentNotification.reminder.update_all(sent_at: dates.first)

    patient_not_sent_reminder_joined_after_first_date.consent_notifications.update_all(
      sent_at: dates.first + 1.day
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
        programmes:,
        session:,
        type: :initial_reminder
      )
      perform_now
    end

    it "records a notification" do
      expect { perform_now }.to change(ConsentNotification, :count).by(1)
    end

    context "when location is a generic clinic" do
      let(:location) { create(:generic_clinic, team:) }

      it "doesn't send any notifications" do
        expect(ConsentNotification).not_to receive(:create_and_send!)
        perform_now
      end
    end
  end

  context "six days before the first session with reminders already sent" do
    let(:today) { dates.first - 6.days }

    before do
      create(
        :consent_notification,
        :initial_reminder,
        patient: patient_not_sent_reminder,
        session:
      )
    end

    it "doesn't send any notifications" do
      expect(ConsentNotification).not_to receive(:create_and_send!)
      perform_now
    end
  end

  context "one day after the first session" do
    let(:today) { dates.first + 1.day }

    it "doesn't send a reminder to the patient who just joined" do
      expect(ConsentNotification).not_to receive(:create_and_send!).with(
        patient: patient_not_sent_reminder_joined_after_first_date,
        programmes:,
        session:,
        type: :initial_reminder
      )

      perform_now

      expect(
        patient_not_sent_reminder_joined_after_first_date.consent_notifications.count
      ).to eq(1)
    end
  end

  context "one week before the second session" do
    let(:today) { dates.last - 1.week }

    it "sends notifications to three patients" do
      expect(ConsentNotification).to receive(:create_and_send!).once.with(
        patient: patient_not_sent_reminder,
        programmes:,
        session:,
        type: :initial_reminder
      )

      expect(ConsentNotification).to receive(:create_and_send!).once.with(
        patient: patient_not_sent_reminder_joined_after_first_date,
        programmes:,
        session:,
        type: :initial_reminder
      )

      expect(ConsentNotification).to receive(:create_and_send!).once.with(
        patient: patient_with_initial_reminder_sent,
        programmes:,
        session:,
        type: :subsequent_reminder
      )

      perform_now
    end

    it "records the notifications" do
      expect { perform_now }.to change(ConsentNotification, :count).by(3)
    end
  end
end
