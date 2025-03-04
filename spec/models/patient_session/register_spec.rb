# frozen_string_literal: true

describe PatientSession::Register do
  subject(:instance) { described_class.new(patient_session) }

  let(:patient) { create(:patient) }
  let(:session) { create(:session, dates: [Date.yesterday, Date.current]) }
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

      it { should be(described_class::PRESENT) }
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

      it { should be(described_class::ABSENT) }
    end
  end
end
