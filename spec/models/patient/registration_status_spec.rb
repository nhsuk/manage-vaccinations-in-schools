# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_registration_statuses
#
#  id         :bigint           not null, primary key
#  status     :integer          default("unknown"), not null
#  patient_id :bigint           not null
#  session_id :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_session_id_2ff02d8889            (patient_id,session_id) UNIQUE
#  index_patient_registration_statuses_on_patient_id  (patient_id)
#  index_patient_registration_statuses_on_session_id  (session_id)
#  index_patient_registration_statuses_on_status      (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (session_id => sessions.id) ON DELETE => cascade
#
describe Patient::RegistrationStatus do
  subject(:patient_registration_status) do
    build(:patient_registration_status, patient:, session:)
  end

  around { |example| travel_to(Date.new(2025, 8, 31)) { example.run } }

  let(:programmes) do
    [create(:programme, :menacwy), create(:programme, :td_ipv)]
  end
  let(:patient) { create(:patient, year_group: 9) }
  let(:session) do
    create(:session, dates: [Date.yesterday, Date.current], programmes:)
  end

  it do
    expect(patient_registration_status).to define_enum_for(:status).with_values(
      %i[unknown attending not_attending completed]
    )
  end

  describe "associations" do
    it { should belong_to(:patient) }
    it { should belong_to(:session) }
  end

  describe "#session_attendance" do
    subject do
      described_class
        .includes(:session_attendances)
        .find(patient_registration_status.id)
        .session_attendance
    end

    let(:patient_registration_status) do
      create(:patient_registration_status, patient:, session:)
    end

    context "with no attendances" do
      it { should be_nil }
    end

    context "with no session date today" do
      let(:session) { create(:session, date: Date.yesterday, programmes:) }

      it { should be_nil }
    end

    context "with an attendance today and yesterday" do
      let(:today_session_attendance) do
        create(
          :session_attendance,
          :present,
          patient:,
          session_date: session.session_dates.find_by(value: Date.current)
        )
      end

      before do
        create(
          :session_attendance,
          :absent,
          patient:,
          session_date: session.session_dates.find_by(value: Date.yesterday)
        )
      end

      it { should eq(today_session_attendance) }
    end
  end

  describe "#status" do
    subject { patient_registration_status.assign_status }

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
