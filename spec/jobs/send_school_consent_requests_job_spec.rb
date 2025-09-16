# frozen_string_literal: true

describe SendSchoolConsentRequestsJob do
  subject(:perform_now) { described_class.perform_now(session) }

  let(:today) { Date.new(2025, 7, 1) }
  let(:programmes) { [create(:programme)] }
  let(:parents) { create_list(:parent, 2) }
  let(:patient_with_request_sent) do
    create(:patient, :consent_request_sent, programmes:)
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
      patient_with_request_sent,
      patient_not_sent_request,
      patient_with_consent,
      deceased_patient,
      invalid_patient,
      restricted_patient
    ]
  end

  before do
    patients.each { |patient| create(:patient_session, patient:, session:) }
  end

  around { |example| travel_to(today) { example.run } }

  context "when session is unscheduled" do
    let(:session) { create(:session, :unscheduled, programmes:) }

    it "doesn't send any notifications" do
      expect(ConsentNotification).not_to receive(:create_and_send!)
      perform_now
    end
  end

  context "when session is scheduled" do
    let(:session) do
      create(
        :session,
        programmes:,
        date: 3.weeks.from_now.to_date,
        send_consent_requests_at: Date.current
      )
    end

    it "sends notifications to one patient" do
      expect(ConsentNotification).to receive(:create_and_send!).once.with(
        patient: patient_not_sent_request,
        programmes:,
        session:,
        type: :request,
        current_user: nil
      )
      perform_now
    end

    context "with Td/IPV and MenACWY" do
      let(:programmes) do
        [create(:programme, :menacwy), create(:programme, :td_ipv)]
      end

      it "sends one notification to one patient" do
        expect(ConsentNotification).to receive(:create_and_send!).once.with(
          patient: patient_not_sent_request,
          programmes:,
          session:,
          current_user: nil,
          type: :request
        )
        perform_now
      end
    end

    context "with HPV, Td/IPV and MenACWY" do
      let(:hpv_programme) { create(:programme, :hpv) }
      let(:menacwy_programme) { create(:programme, :menacwy) }
      let(:td_ipv_programme) { create(:programme, :td_ipv) }

      let(:programmes) { [hpv_programme, menacwy_programme, td_ipv_programme] }

      context "when the patient is in Year 8" do
        let(:patient_not_sent_request) do
          create(:patient, year_group: 8, parents:, programmes:)
        end

        it "sends only one notification for HPV" do
          expect(ConsentNotification).to receive(:create_and_send!).once.with(
            patient: patient_not_sent_request,
            programmes: [hpv_programme],
            session:,
            current_user: nil,
            type: :request
          )
          perform_now
        end
      end

      context "when the patient is in Year 9" do
        let(:patient_not_sent_request) do
          create(:patient, year_group: 9, parents:, programmes:)
        end

        it "sends two notifications for HPV, and MenACWY and Td/IPV" do
          expect(ConsentNotification).to receive(:create_and_send!).with(
            patient: patient_not_sent_request,
            programmes: [hpv_programme],
            session:,
            type: :request,
            current_user: nil
          )
          expect(ConsentNotification).to receive(:create_and_send!).with(
            patient: patient_not_sent_request,
            programmes: [menacwy_programme, td_ipv_programme],
            session:,
            type: :request,
            current_user: nil
          )
          perform_now
        end
      end
    end

    context "when location is a generic clinic" do
      let(:team) { create(:team, programmes:) }
      let(:location) { create(:generic_clinic, team:) }
      let(:session) { create(:session, programmes:, team:) }

      it "doesn't send any notifications" do
        expect(ConsentNotification).not_to receive(:create_and_send!)
        perform_now
      end
    end
  end
end
