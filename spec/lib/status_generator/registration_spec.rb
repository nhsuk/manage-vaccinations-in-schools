# frozen_string_literal: true

describe StatusGenerator::Registration do
  subject(:generator) do
    described_class.new(
      patient_session:,
      session_attendance:
        patient_session.session_attendances.find_by(
          session_date: session.session_dates.last
        ),
      vaccination_records: patient.vaccination_records
    )
  end

  around { |example| travel_to(Date.new(2025, 8, 31)) { example.run } }

  let(:programmes) do
    [create(:programme, :menacwy), create(:programme, :td_ipv)]
  end
  let(:patient) { create(:patient, year_group: 9) }
  let(:session) do
    create(:session, dates: [Date.yesterday, Date.current], programmes:)
  end
  let(:patient_session) { create(:patient_session, patient:, session:) }

  describe "#status" do
    subject { generator.status }

    context "with no session attendance" do
      it { should be(:unknown) }
    end

    context "with a session attendance for a different day to today" do
      before do
        create(
          :session_attendance,
          :present,
          patient:,
          session_date: session.session_dates.first
        )
      end

      it { should be(:unknown) }
    end

    context "with a present session attendance for today" do
      before do
        create(
          :session_attendance,
          :present,
          patient:,
          session_date: session.session_dates.second
        )
      end

      it { should be(:attending) }
    end

    context "with an absent session attendance for today" do
      before do
        create(
          :session_attendance,
          :absent,
          patient:,
          session_date: session.session_dates.second
        )
      end

      it { should be(:not_attending) }
    end

    context "with an outcome for one of the programmes" do
      before do
        create(
          :vaccination_record,
          patient:,
          session:,
          programme: programmes.first
        )
      end

      it { should be(:unknown) }
    end

    context "with an outcome for both of the programmes" do
      before do
        programmes.each do |programme|
          create(:vaccination_record, patient:, session:, programme:)
        end
      end

      it { should be(:completed) }
    end
  end
end
