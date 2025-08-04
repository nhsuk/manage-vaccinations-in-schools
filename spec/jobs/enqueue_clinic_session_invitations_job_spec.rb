# frozen_string_literal: true

describe EnqueueClinicSessionInvitationsJob do
  subject(:perform_now) { described_class.perform_now }

  around { |example| travel_to(Date.new(2025, 1, 1)) { example.run } }

  let(:programmes) { [create(:programme, :hpv)] }
  let(:organisation) { create(:organisation, programmes:) }
  let(:parents) { create_list(:parent, 2) }
  let(:patient) { create(:patient, parents:, year_group: 8) }
  let(:location) { create(:generic_clinic, organisation:) }

  context "for a scheduled clinic session in 3 weeks" do
    let(:date) { 3.weeks.from_now.to_date }
    let(:session) do
      create(:session, programmes:, date:, location:, organisation:)
    end
    let(:patient_session) { create(:patient_session, patient:, session:) }

    it "sends a notification" do
      expect(SessionNotification).to receive(:create_and_send!).once.with(
        patient_session:,
        session_date: date,
        type: :clinic_initial_invitation
      )
      perform_now
    end

    context "when patient goes to a school" do
      let(:patient) { create(:patient, parents:, school: create(:school)) }

      it "doesn't send any notifications" do
        expect(SessionNotification).not_to receive(:create_and_send!)
        perform_now
      end
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
        before { session.session_dates.create!(value: date + 1.week) }

        let(:today) { date + 1.day }

        it "doesn't send any notifications" do
          expect(SessionNotification).not_to receive(:create_and_send!)
          perform_now
        end
      end
    end

    context "when already vaccinated" do
      before do
        create(
          :vaccination_record,
          patient:,
          session:,
          programme: programmes.first,
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
          patient:,
          programme: programmes.first,
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
    let(:session) do
      create(:session, programmes:, date:, location:, organisation:)
    end
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
    let(:session) do
      create(:session, programmes:, date:, location:, organisation:)
    end
    let(:patient_session) { create(:patient_session, patient:, session:) }

    it "doesn't send any notifications" do
      expect(SessionNotification).not_to receive(:create_and_send!)
      perform_now
    end
  end

  context "for a school session in 3 weeks time" do
    let(:location) { create(:school, organisation:) }

    before do
      create(
        :session,
        programmes:,
        date: 3.weeks.from_now.to_date,
        patients: [patient],
        organisation:,
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
        programmes:,
        date: Date.yesterday,
        patients: [patient],
        location:,
        organisation:
      )
    end

    it "doesn't send any notifications" do
      expect(SessionNotification).not_to receive(:create_and_send!)
      perform_now
    end
  end
end
