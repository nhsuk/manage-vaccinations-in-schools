# frozen_string_literal: true

describe AttendanceRecordPolicy do
  subject(:policy) { described_class.new(user, attendance_record) }

  let(:user) { create(:nurse) }

  let(:programmes) { [CachedProgramme.hpv, CachedProgramme.flu] }
  let(:team) { create(:team, programmes:) }
  let(:session) { create(:session, team:, programmes:) }
  let(:patient) { create(:patient, session:, year_group: 8) }

  shared_examples "allow if not yet vaccinated or seen by nurse" do
    context "with a new session attendance" do
      let(:attendance_record) { build(:attendance_record, patient:, session:) }

      it { should be(true) }
    end

    context "with session attendance and one vaccination record from a different session" do
      let(:attendance_record) { build(:attendance_record, patient:, session:) }

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
      let(:attendance_record) { build(:attendance_record, patient:, session:) }

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
      let(:attendance_record) { build(:attendance_record, patient:, session:) }

      around { |example| travel_to(Date.new(2025, 8, 31)) { example.run } }

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
