# frozen_string_literal: true

describe SendAutomaticSchoolConsentRemindersJob do
  subject(:perform_now) { described_class.perform_now(session) }

  let(:programmes) { [create(:programme, :flu)] }
  let(:user) { create(:user, team:) }

  let(:parents) { create_list(:parent, 2) }

  let(:manual_reminder_patient) { create(:patient, parents:, team:) }

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
  let(:patient_vaccinated_last_year) do
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
  let(:archived_patient) { create(:patient, :archived, team:) }
  let!(:patients) do
    [
      manual_reminder_patient,
      patient_with_initial_reminder_sent,
      patient_not_sent_reminder,
      patient_not_sent_reminder_joined_after_first_date,
      patient_not_sent_request,
      patient_with_consent,
      deceased_patient,
      invalid_patient,
      restricted_patient,
      archived_patient
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
      programmes:,
      team:
    )
  end

  before do
    patients.each { |patient| create(:patient_location, patient:, session:) }
    ConsentNotification.request.update_all(sent_at: dates.first - 1.week)
    ConsentNotification.reminder.update_all(sent_at: dates.first)

    patient_not_sent_reminder_joined_after_first_date.consent_notifications.update_all(
      sent_at: dates.first + 1.day
    )

    create(
      :consent_notification,
      patient: manual_reminder_patient,
      session:,
      programmes:,
      type: :initial_reminder,
      sent_at: dates.first - 9.days,
      sent_by: user
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
        programmes: [programmes.first],
        session:,
        type: :initial_reminder,
        current_user: nil
      )
      perform_now
    end

    it "records notifications" do
      expect { perform_now }.to change(ConsentNotification, :count).by(1)
    end

    context "when location is a generic clinic" do
      let(:location) { create(:generic_clinic, team:) }

      it "doesn't send any notifications" do
        expect(ConsentNotification).not_to receive(:create_and_send!)
        perform_now
      end
    end

    context "when a manual reminder was sent more than three days ago" do
      before do
        create(
          :consent_notification,
          patient: patient_not_sent_reminder,
          session:,
          programmes:,
          type: :initial_reminder,
          sent_at: 4.days.ago,
          sent_by: user
        )
      end

      it "sends automatic reminders" do
        expect { perform_now }.to change(ConsentNotification, :count).by(1)

        notification = ConsentNotification.last
        expect(notification.patient).to eq(patient_not_sent_reminder)
        expect(notification.programmes.length).to eq(1)
        expect(notification.automated_reminder?).to be true

        programme_types = notification.programmes.map(&:type)
        expect(programme_types).to match_array(programmes.map(&:type))
      end
    end

    context "when a manual reminder was sent less than three days ago" do
      let(:user) { create(:user, team:) }

      before do
        create(
          :consent_notification,
          patient: patient_not_sent_reminder,
          session:,
          programmes:,
          type: :initial_reminder,
          sent_at: 2.days.ago,
          sent_by: user
        )
      end

      it "does not send an automatic reminder" do
        expect { perform_now }.not_to change(ConsentNotification, :count)
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

  context "five days before the first session, eight before the second" do
    let(:today) { dates.first - 5.days }
    let(:user) { create(:user, team:) }

    context "when a manual reminder was sent less than three days before the reminder should have gone out" do
      it "does not send an automatic reminder because the first session's reminder should be skipped" do
        expect { perform_now }.not_to change(
          ConsentNotification.where(patient_id: manual_reminder_patient.id),
          :count
        )
      end
    end
  end

  context "2 days before the first session, six before the second" do
    let(:today) { dates.first - 2.days }
    let(:user) { create(:user, team:) }

    context "when a manual reminder was sent less than three days before the reminder should have gone out" do
      it "sends the reminder for the second session" do
        expect { perform_now }.to change(ConsentNotification, :count).by(1)
      end
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
        type: :initial_reminder,
        current_user: nil
      )

      expect(ConsentNotification).to receive(:create_and_send!).once.with(
        patient: patient_not_sent_reminder_joined_after_first_date,
        programmes:,
        session:,
        type: :initial_reminder,
        current_user: nil
      )

      expect(ConsentNotification).to receive(:create_and_send!).once.with(
        patient: patient_with_initial_reminder_sent,
        programmes:,
        session:,
        type: :subsequent_reminder,
        current_user: nil
      )

      perform_now
    end

    it "records the notifications" do
      expect { perform_now }.to change(ConsentNotification, :count).by(3)
    end
  end
end
