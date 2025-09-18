# frozen_string_literal: true

describe StatusGenerator::Registration do
  subject(:generator) do
    described_class.new(
      patient:,
      session:,
      attendance_record:
        patient.attendance_records.find_by(date: session.dates.last),
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
  let(:patient_location) { create(:patient_location, patient:, session:) }

  describe "#status" do
    subject { generator.status }

    context "with no session attendance" do
      it { should be(:unknown) }
    end

    context "with a session attendance for a different day to today" do
      before do
        create(
          :attendance_record,
          :present,
          patient:,
          session:,
          date: session.dates.first
        )
      end

      it { should be(:unknown) }
    end

    context "with a present session attendance for today" do
      before do
        create(
          :attendance_record,
          :present,
          patient:,
          session:,
          date: session.dates.second
        )
      end

      it { should be(:attending) }
    end

    context "with an absent session attendance for today" do
      before do
        create(
          :attendance_record,
          :absent,
          patient:,
          session:,
          date: session.dates.second
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
