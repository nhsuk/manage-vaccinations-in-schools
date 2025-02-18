# frozen_string_literal: true

describe HertsConsentReminders do
  let(:session_date) { Time.zone.today + 13.days }
  let(:session) { create(:session, programme:, dates: [session_date]) }
  let(:programme) { create(:programme) }
  let(:patient) { create(:patient, :consent_request_sent, session:) }
  let(:consent_request) { create(:consent_notification, programme:, patient:) }

  describe ".send_consent_reminders" do
    before do
      allow(described_class).to receive(:filter_patients_to_send_consent).with(
        session
      ).and_return([[patient, programme, :initial_reminder]])

      allow(ConsentNotification).to receive(:create_and_send!)
    end

    it "sends notifications via ConsentNotification" do
      described_class.send_consent_reminders(session)

      expect(ConsentNotification).to have_received(:create_and_send!).with(
        patient:,
        programme:,
        session:,
        type: :initial_reminder
      )
    end

    it "does nothing when session is not open for consent" do
      session.session_dates.destroy_all

      described_class.send_consent_reminders(session)

      expect(ConsentNotification).not_to have_received(:create_and_send!)
    end
  end

  describe ".should_send_notification?" do
    subject do
      described_class.should_send_notification?(patient:, programme:, session:)
    end

    let(:initial_reminder) do
      create(
        :consent_notification,
        :initial_reminder,
        patient:,
        programme:,
        session:
      )
    end

    let(:subsequent_reminder1) do
      create(
        :consent_notification,
        :subsequent_reminder,
        patient:,
        programme:,
        session:
      )
    end

    let(:subsequent_reminder2) do
      create(
        :consent_notification,
        :subsequent_reminder,
        patient:,
        programme:,
        session:
      )
    end

    it { should be true }

    context "send_notifications? is false" do
      before do
        allow(patient).to receive(:send_notifications?).and_return(false)
      end

      it { should be false }
    end

    context "patient already has consent" do
      before { allow(patient).to receive(:has_consent?).and_return(true) }

      it { should be false }
    end

    context "no consent request has been sent yet" do
      before { patient.consent_notifications.destroy_all }

      it { should be false }
    end

    context "15 days before the session" do
      let(:session_date) { Time.zone.today + 15.days }

      it { should be false }
    end

    context "14 days before the session" do
      let(:session_date) { Time.zone.today + 14.days }

      it { should be true }
    end

    context "14 days before the session, reminder sent" do
      before { initial_reminder }

      let(:session_date) { Time.zone.today + 14.days }

      it { should be false }
    end

    context "8 days before the session, reminder sent" do
      before { initial_reminder }

      let(:session_date) { Time.zone.today + 8.days }

      it { should be false }
    end

    context "7 days before the session, reminder sent" do
      before { initial_reminder }

      let(:session_date) { Time.zone.today + 7.days }

      it { should be true }
    end

    context "7 days before the session, 2 reminders sent" do
      before do
        initial_reminder
        subsequent_reminder1
      end

      let(:session_date) { Time.zone.today + 7.days }

      it { should be false }
    end

    context "4 days before the session, 2 reminder sent" do
      before do
        initial_reminder
        subsequent_reminder1
      end

      let(:session_date) { Time.zone.today + 4.days }

      it { should be false }
    end

    context "3 days before the session, 2 reminder sent" do
      before do
        initial_reminder
        subsequent_reminder1
      end

      let(:session_date) { Time.zone.today + 3.days }

      it { should be true }
    end

    context "3 days before the session, 3 reminder sent" do
      before do
        initial_reminder
        subsequent_reminder1
        subsequent_reminder2
      end

      let(:session_date) { Time.zone.today + 3.days }

      it { should be false }
    end
  end

  describe ".filter_patients_to_send_consent" do
    before { patient }

    let(:session_date) { Time.zone.today + 7.days }

    it "skips patients who should not receive a reminder" do
      allow(described_class).to receive(:should_send_notification?).and_return(
        false
      )

      result = described_class.filter_patients_to_send_consent(session)

      expect(result).to be_empty
    end

    it "returns initial reminder type for first reminder" do
      result = described_class.filter_patients_to_send_consent(session)

      expect(result.first[2]).to eq(:initial_reminder)
    end

    it "returns subsequent reminder type for later reminders" do
      create(:consent_notification, :initial_reminder, patient:, programme:)

      result = described_class.filter_patients_to_send_consent(session)

      expect(result.first[2]).to eq(:subsequent_reminder)
    end
  end
end
