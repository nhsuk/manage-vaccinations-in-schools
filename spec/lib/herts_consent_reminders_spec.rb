# frozen_string_literal: true

describe HertsConsentReminders do
  let(:programme) { create(:programme, :hpv) }
  let(:organisation) do
    create(:organisation, ods_code: "RY4", programmes: [programme])
  end
  let(:session_date) { 13.days.from_now }
  let(:session) do
    create(:session, programme:, organisation:, dates: [session_date])
  end
  let(:patient) { create(:patient, :consent_request_sent, session:) }
  let(:consent_request) do
    create(
      :consent_notification,
      :request,
      sent_at: initial_reminder_sent_at,
      patient:,
      programme:,
      session:
    )
  end

  describe ".sessions_with_reminders_due" do
    subject { described_class.sessions_with_reminders_due }

    before { session }

    context "session is 15 days away" do
      let(:session_date) { 15.days.from_now }

      it { should_not include(session) }
    end

    context "session is 14 days away" do
      let(:session_date) { 14.days.from_now }

      it { should include(session) }
    end

    context "session is 13 days away" do
      let(:session_date) { 13.days.from_now }

      it { should_not include(session) }
    end

    context "session is 7 days away" do
      let(:session_date) { 7.days.from_now }

      it { should include(session) }
    end

    context "session is 3 days away" do
      let(:session_date) { 3.days.from_now }

      it { should include(session) }
    end

    describe "specifying the date" do
      subject do
        described_class.sessions_with_reminders_due(
          on_date: Date.current + 1.day
        )
      end

      let(:session_date) { 15.days.from_now }

      it { should include(session) }
    end
  end

  describe ".send_consent_reminders" do
    before do
      allow(described_class).to receive(:filter_patients_to_send_consent).with(
        session,
        on_date: Date.current
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

    let(:initial_reminder_sent_at) { 3.days.ago }
    let(:initial_reminder) do
      create(
        :consent_notification,
        :initial_reminder,
        sent_at: initial_reminder_sent_at,
        patient:,
        programme:,
        session:
      )
    end

    let(:subsequent_reminder_sent_at) { 2.days.ago }
    let(:subsequent_reminder) do
      create(
        :consent_notification,
        :subsequent_reminder,
        sent_at: subsequent_reminder_sent_at,
        patient:,
        programme:,
        session:
      )
    end

    let(:subsequent_reminder2_sent_at) { 1.day.ago }
    let(:subsequent_reminder2) do
      create(
        :consent_notification,
        :subsequent_reminder,
        sent_at: subsequent_reminder2_sent_at,
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

    context "15 days before the session, no reminder sent" do
      let(:session_date) { 15.days.from_now }

      it { should be false }
    end

    context "14 days before the session, no reminder sent" do
      let(:session_date) { 14.days.from_now }

      it { should be true }
    end

    context "14 days before the session, initial reminder sent" do
      before { initial_reminder }

      let(:session_date) { 14.days.from_now }

      it { should be false }
    end

    context "14 days before the session, initial reminder sent today" do
      before { initial_reminder }

      let(:initial_reminder_sent_at) { Date.current }
      let(:session_date) { 14.days.from_now }

      it { should be false }
    end

    context "8 days before the session, no reminder sent" do
      let(:session_date) { 8.days.from_now }

      it { should be true }
    end

    context "8 days before the session, initial reminder sent" do
      before { initial_reminder }

      let(:initial_reminder_sent_at) { 6.days.ago }
      let(:session_date) { 8.days.from_now }

      it { should be false }
    end

    context "7 days before the session, no reminders sent" do
      let(:session_date) { 7.days.from_now }

      it { should be true }
    end

    context "7 days before the session, initial reminder sent" do
      before { initial_reminder }

      let(:initial_reminder_sent_at) { 1.day.ago }
      let(:session_date) { 7.days.from_now }

      it { should be true }
    end

    context "7 days before the session, initial reminder sent today" do
      before { initial_reminder }

      let(:initial_reminder_sent_at) { Date.current }
      let(:session_date) { 7.days.from_now }

      it { should be false }
    end

    context "7 days before the session, 2 reminders sent before today" do
      before do
        initial_reminder
        subsequent_reminder
      end

      let(:session_date) { 7.days.from_now }

      it { should be false }
    end

    context "6 days before the session, initial reminder sent yesterday" do
      before { initial_reminder }

      let(:initial_reminder_sent_at) { 1.day.ago }
      let(:session_date) { 6.days.from_now }

      it { should be true }
    end

    context "3 days before the session, 2 reminder sent" do
      before do
        initial_reminder
        subsequent_reminder
      end

      let(:session_date) { 3.days.from_now }

      it { should be true }
    end

    context "3 days before the session, 3 reminder sent" do
      before do
        initial_reminder
        subsequent_reminder
        subsequent_reminder2
      end

      let(:session_date) { 3.days.from_now }

      it { should be false }
    end

    context "no session date" do
      before { session.session_dates.destroy_all }

      it { should be false }
    end

    context "last request was sent today" do
      before { consent_request.update!(sent_at: Date.current) }

      it { should be false }
    end

    context "last request was sent yesterday" do
      before { consent_request.update!(sent_at: 1.day.ago) }

      it { should be true }
    end

    context "initial reminder was sent today" do
      before { initial_reminder.update!(sent_at: Date.current) }

      it { should be false }
    end

    context "initial reminder was sent yesterday" do
      before { initial_reminder.update!(sent_at: 1.day.ago) }

      it { should be false }
    end

    context "subsequent reminder was sent today" do
      before { subsequent_reminder.update!(sent_at: Date.current) }

      it { should be false }
    end

    context "subsequent reminder was sent yesterday" do
      before { subsequent_reminder.update!(sent_at: 1.day.ago) }

      it { should be false }
    end
  end

  describe ".filter_patients_to_send_consent" do
    before { patient }

    let(:session_date) { 7.days.from_now }

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
      create(
        :consent_notification,
        :initial_reminder,
        sent_at: 1.day.ago,
        patient:,
        programme:
      )

      result = described_class.filter_patients_to_send_consent(session)

      expect(result.first[2]).to eq(:subsequent_reminder)
    end
  end
end
