# frozen_string_literal: true

describe PatientSession::RegisterOutcome do
  subject(:instance) { described_class.new(patient_session) }

  let(:programmes) do
    [create(:programme, :menacwy), create(:programme, :td_ipv)]
  end
  let(:patient) { create(:patient, year_group: 9) }
  let(:session) do
    create(:session, dates: [Date.yesterday, Date.current], programmes:)
  end
  let(:patient_session) { create(:patient_session, patient:, session:) }

  before { patient.strict_loading!(false) }

  describe "#status" do
    subject(:status) { instance.status }

    context "with no session attendance" do
      it { should be(described_class::UNKNOWN) }
    end

    context "with a session attendance for a different day to today" do
      before do
        create(
          :session_attendance,
          :present,
          patient_session:,
          session_date: session.session_dates.first
        )
      end

      it { should be(described_class::UNKNOWN) }
    end

    context "with a present session attendance for today" do
      before do
        create(
          :session_attendance,
          :present,
          patient_session:,
          session_date: session.session_dates.second
        )
      end

      it { should be(described_class::ATTENDING) }
    end

    context "with an absent session attendance for today" do
      before do
        create(
          :session_attendance,
          :absent,
          patient_session:,
          session_date: session.session_dates.second
        )
      end

      it { should be(described_class::NOT_ATTENDING) }
    end

    context "with an outcome for one of the sessions" do
      before do
        create(
          :vaccination_record,
          patient:,
          session:,
          programme: programmes.first
        )
      end

      it { should be(described_class::UNKNOWN) }
    end

    context "with an outcome for both of the sessions" do
      before do
        programmes.each do |programme|
          create(:vaccination_record, patient:, session:, programme:)
        end
      end

      it { should be(described_class::COMPLETED) }
    end
  end
end
