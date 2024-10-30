# frozen_string_literal: true

describe ClinicSessionInvitationsJob do
  subject(:perform_now) { described_class.perform_now }

  let(:programme) { create(:programme) }
  let(:team) { create(:team, programmes: [programme]) }
  let(:parents) { create_list(:parent, 2, :recorded) }
  let(:patient) { create(:patient, parents:) }
  let(:location) { create(:location, :generic_clinic, team:) }

  context "for a scheduled clinic session in 3 weeks" do
    let(:date) { 3.weeks.from_now.to_date }
    let(:session) { create(:session, programme:, date:, location:, team:) }
    let(:patient_session) { create(:patient_session, patient:, session:) }

    it "sends a notification" do
      expect(SessionNotification).to receive(:create_and_send!).once.with(
        patient_session:,
        session_date: date,
        type: :clinic_initial_invitation
      )
      perform_now
    end

    context "when already sent for that date" do
      before do
        create(
          :session_notification,
          :clinic_initial_invitation,
          session:,
          patient:
        )
      end

      it "doesn't send any notifications" do
        expect(SessionNotification).not_to receive(:create_and_send!)
        perform_now
      end

      context "with a second date a week later" do
        before { session.dates.create!(value: date + 1.week) }

        let(:today) { date + 1.day }

        it "sends a second notification" do
          expect(SessionNotification).to receive(:create_and_send!).once.with(
            patient_session:,
            session_date: date + 1.week,
            type: :clinic_subsequent_invitation
          )
          travel_to(today) { perform_now }
        end
      end
    end

    context "when already vaccinated" do
      before do
        create(
          :vaccination_record,
          patient_session:,
          programme:,
          location_name: "A clinic."
        )
      end

      it "doesn't send any notifications" do
        expect(SessionNotification).not_to receive(:create_and_send!)
        perform_now
      end
    end

    context "when refused consent has been received" do
      before do
        create(
          :consent,
          :refused,
          :recorded,
          patient:,
          programme:,
          parent: parents.first
        )
      end

      it "doesn't send any notifications" do
        expect(SessionNotification).not_to receive(:create_and_send!)
        perform_now
      end
    end

    context "if the patient is deceased" do
      let(:patient) { create(:patient, :deceased, parents:) }

      it "doesn't send any notifications" do
        expect(SessionNotification).not_to receive(:create_and_send!)
        perform_now
      end
    end

    context "if the patient is invalid" do
      let(:patient) { create(:patient, :invalidated, parents:) }

      it "doesn't send any notifications" do
        expect(SessionNotification).not_to receive(:create_and_send!)
        perform_now
      end
    end

    context "if the patient is restricted" do
      let(:patient) { create(:patient, :restricted, parents:) }

      it "doesn't send any notifications" do
        expect(SessionNotification).not_to receive(:create_and_send!)
        perform_now
      end
    end
  end

  context "for a scheduled clinic session in 2 weeks" do
    let(:date) { 2.weeks.from_now.to_date }
    let(:session) { create(:session, programme:, date:, location:, team:) }
    let(:patient_session) { create(:patient_session, patient:, session:) }

    it "sends a notification" do
      expect(SessionNotification).to receive(:create_and_send!).once.with(
        patient_session:,
        session_date: date,
        type: :clinic_initial_invitation
      )
      perform_now
    end
  end

  context "for a scheduled clinic session in 4 weeks" do
    let(:date) { 4.weeks.from_now.to_date }
    let(:session) { create(:session, programme:, date:, location:, team:) }
    let(:patient_session) { create(:patient_session, patient:, session:) }

    it "doesn't send any notifications" do
      expect(SessionNotification).not_to receive(:create_and_send!)
      perform_now
    end
  end

  context "for a school session in 3 weeks time" do
    let(:location) { create(:location, :school, team:) }

    before do
      create(
        :session,
        programme:,
        date: 3.weeks.from_now.to_date,
        patients: [patient],
        team:,
        location:
      )
    end

    it "doesn't send any notifications" do
      expect(SessionNotification).not_to receive(:create_and_send!)
      perform_now
    end
  end

  context "for a clinic session yesterday" do
    before do
      create(
        :session,
        programme:,
        date: Date.yesterday,
        patients: [patient],
        location:,
        team:
      )
    end

    it "doesn't send any notifications" do
      expect(SessionNotification).not_to receive(:create_and_send!)
      perform_now
    end
  end
end
