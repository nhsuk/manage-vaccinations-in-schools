# frozen_string_literal: true

describe SendClinicSubsequentInvitationsJob do
  subject(:perform_now) { described_class.perform_now(session) }

  around { |example| travel_to(Date.new(2025, 8, 1)) { example.run } }

  let(:programmes) { [Programme.hpv] }
  let(:team) { create(:team, programmes:) }
  let(:parents) { create_list(:parent, 2) }
  let(:patient) { create(:patient, parents:, year_group: 9, session:) }
  let(:location) { create(:generic_clinic, team:, academic_year: 2024) }
  let(:academic_year) { session.academic_year }

  let(:session) do
    create(
      :session,
      programmes:,
      dates: [1.week.ago.to_date, 1.week.from_now.to_date],
      location:,
      team:
    )
  end

  it "doesn't send any notifications" do
    expect(ClinicNotification).not_to receive(:create_and_send!)
    perform_now
  end

  context "when already sent for that date" do
    before do
      create(:clinic_notification, :initial_invitation, session:, patient:)
    end

    it "sends a notification" do
      expect(ClinicNotification).to receive(:create_and_send!).once.with(
        patient:,
        team:,
        academic_year:,
        programmes:,
        type: :subsequent_invitation
      )
      perform_now
    end

    context "when already vaccinated" do
      before do
        create(
          :patient_programme_status,
          :vaccinated_fully,
          patient:,
          programme: programmes.first
        )
        create(
          :vaccination_record,
          patient:,
          session:,
          programme: programmes.first,
          location_name: "A clinic."
        )
      end

      it "doesn't send any notifications" do
        expect(ClinicNotification).not_to receive(:create_and_send!)
        perform_now
      end
    end

    context "when refused consent has been received" do
      let(:patient) do
        create(:patient, :consent_refused, parents:, programmes:)
      end

      it "doesn't send any notifications" do
        expect(ClinicNotification).not_to receive(:create_and_send!)
        perform_now
      end
    end

    context "if the patient is deceased" do
      let(:patient) { create(:patient, :deceased, parents:) }

      it "doesn't send any notifications" do
        expect(ClinicNotification).not_to receive(:create_and_send!)
        perform_now
      end
    end

    context "if the patient is invalid" do
      let(:patient) { create(:patient, :invalidated, parents:) }

      it "doesn't send any notifications" do
        expect(ClinicNotification).not_to receive(:create_and_send!)
        perform_now
      end
    end

    context "if the patient is restricted" do
      let(:patient) { create(:patient, :restricted, parents:) }

      it "doesn't send any notifications" do
        expect(ClinicNotification).not_to receive(:create_and_send!)
        perform_now
      end
    end

    context "if the patient is archived" do
      let(:patient) { create(:patient, :archived, parents:, team:) }

      it "doesn't send any notifications" do
        expect(ClinicNotification).not_to receive(:create_and_send!)
        perform_now
      end
    end
  end

  context "when eligible for multiple programmes but already vaccinated for one" do
    let(:programmes) { [Programme.hpv, Programme.menacwy, Programme.td_ipv] }

    before do
      create(:vaccination_record, patient:, programme: programmes.first)

      create(
        :clinic_notification,
        :initial_invitation,
        patient:,
        academic_year:,
        programmes: [programmes.second, programmes.third],
        team:
      )

      StatusUpdater.call(patient:)
    end

    it "sends a subsequent invitation for the non-vaccinated programmes" do
      expect(ClinicNotification).to receive(:create_and_send!).once.with(
        patient:,
        team:,
        academic_year:,
        programmes:,
        type: :subsequent_invitation
      )
      perform_now
    end
  end
end
