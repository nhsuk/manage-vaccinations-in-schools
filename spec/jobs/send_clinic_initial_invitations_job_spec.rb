# frozen_string_literal: true

describe SendClinicInitialInvitationsJob do
  subject(:perform_now) { described_class.perform_now(session) }

  let(:today) { Date.new(2025, 7, 1) }
  let(:programmes) { [create(:programme, :hpv)] }
  let(:team) { create(:team, programmes:) }
  let(:parents) { create_list(:parent, 2) }
  let(:patient) { create(:patient, parents:, year_group: 9, session:) }
  let(:location) { create(:generic_clinic, team:) }
  let(:session) do
    create(
      :session,
      programmes:,
      date: 3.weeks.from_now.to_date,
      location:,
      team:
    )
  end

  around { |example| travel_to(today) { example.run } }

  it "sends a notification" do
    expect(SessionNotification).to receive(:create_and_send!).once.with(
      patient:,
      session:,
      session_date: session.dates.first,
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
  end

  context "when already vaccinated" do
    before do
      create(:vaccination_record, patient:, programme: programmes.first)
      StatusUpdater.call(patient:)
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

      StatusUpdater.call(patient:)
    end

    it "doesn't send any notifications" do
      expect(SessionNotification).not_to receive(:create_and_send!)
      perform_now
    end
  end

  context "when vaccinated for one programme and consent refused for another" do
    let(:programmes) do
      [create(:programme, :menacwy), create(:programme, :td_ipv)]
    end

    before do
      create(:vaccination_record, patient:, programme: programmes.first)

      create(
        :consent,
        :refused,
        patient:,
        programme: programmes.second,
        parent: parents.first
      )

      StatusUpdater.call(patient:)
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
