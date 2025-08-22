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

  let(:programmes) do
    [create(:programme, :menacwy), create(:programme, :td_ipv)]
  end
  let(:patient) { create(:patient, year_group: 9) }
  let(:session) do
    create(:session, dates: [Date.yesterday, Date.current], programmes:)
  end

  it { should belong_to(:patient) }
  it { should belong_to(:session) }

  it do
    expect(patient_registration_status).to define_enum_for(:status).with_values(
      %i[unknown attending not_attending completed]
    )
  end

  describe "#status" do
    subject(:status) { patient_registration_status.assign_status }

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
