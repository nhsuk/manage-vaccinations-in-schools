# frozen_string_literal: true

describe SessionAttendancePolicy do
  subject(:policy) { described_class.new(user, session_attendance) }

  let(:user) { create(:nurse) }

  let(:programmes) { [create(:programme, :hpv), create(:programme, :flu)] }
  let(:team) { create(:team, programmes:) }
  let(:session) { create(:session, team:, programmes:) }
  let(:patient) { create(:patient, session:, year_group: 8) }

  let(:patient_session) { patient.patient_sessions.includes(:session).first }

  shared_examples "allow if not yet vaccinated or seen by nurse" do
    context "with a new session attendance" do
      let(:session_attendance) { build(:session_attendance, patient_session:) }

      it { should be(true) }
    end

    context "with session attendance and one vaccination record from a different session" do
      let(:session_attendance) { build(:session_attendance, patient_session:) }

      before do
        create(
          :vaccination_record,
          patient:,
          programme: programmes.first,
          performed_at: Time.current
        )

        StatusUpdater.call(patient:)
      end

      it { should be(true) }
    end

    context "with session attendance and both vaccination records" do
      let(:session_attendance) { build(:session_attendance, patient_session:) }

      before do
        programmes.each do |programme|
          create(
            :vaccination_record,
            patient:,
            session:,
            programme:,
            performed_at: Time.current
          )
        end

        StatusUpdater.call(patient:)
      end

      it { should be(false) }
    end

    context "with session attendance and both vaccination records from a different date" do
      let(:session_attendance) { build(:session_attendance, patient_session:) }

      before do
        programmes.each do |programme|
          create(
            :vaccination_record,
            patient:,
            session:,
            programme:,
            performed_at: Time.zone.yesterday
          )
        end

        StatusUpdater.call(patient:)
      end

      it { should be(false) }
    end
  end

  describe "#new?" do
    subject(:new?) { policy.new? }

    include_examples "allow if not yet vaccinated or seen by nurse"
  end

  describe "#create?" do
    subject(:create?) { policy.create? }

    include_examples "allow if not yet vaccinated or seen by nurse"
  end

  describe "#edit?" do
    subject(:edit?) { policy.edit? }

    include_examples "allow if not yet vaccinated or seen by nurse"
  end

  describe "#update?" do
    subject(:update?) { policy.update? }

    include_examples "allow if not yet vaccinated or seen by nurse"
  end
end
