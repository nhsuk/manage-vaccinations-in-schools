# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                            :bigint           not null, primary key
#  academic_year                 :integer          not null
#  closed_at                     :datetime
#  days_before_consent_reminders :integer
#  send_consent_requests_at      :date
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  location_id                   :bigint           not null
#  team_id                       :bigint           not null
#
# Indexes
#
#  index_sessions_on_team_id                                    (team_id)
#  index_sessions_on_team_id_and_location_id_and_academic_year  (team_id,location_id,academic_year) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#

describe Session do
  describe "scopes" do
    let(:programme) { create(:programme) }

    let(:today_session) { create(:session, :today, programme:) }
    let(:unscheduled_session) { create(:session, :unscheduled, programme:) }
    let(:completed_session) { create(:session, :completed, programme:) }
    let(:scheduled_session) { create(:session, :scheduled, programme:) }

    describe "#open" do
      subject(:scope) { described_class.open }

      it do
        expect(scope).to contain_exactly(
          today_session,
          unscheduled_session,
          scheduled_session
        )
      end
    end

    describe "#closed" do
      subject(:scope) { described_class.closed }

      it { should contain_exactly(completed_session) }
    end

    describe "#today" do
      subject(:scope) { described_class.today }

      it { should contain_exactly(today_session) }
    end

    describe "#unscheduled" do
      subject(:scope) { described_class.unscheduled }

      it { should contain_exactly(unscheduled_session) }

      context "for a different academic year" do
        let(:unscheduled_session) do
          create(:session, :unscheduled, programme:, academic_year: 2023)
        end

        it { should_not include(unscheduled_session) }
      end
    end

    describe "#scheduled" do
      subject(:scope) { described_class.scheduled }

      it { should contain_exactly(today_session, scheduled_session) }
    end

    describe "#upcoming" do
      subject(:scope) { described_class.upcoming }

      it do
        expect(scope).to contain_exactly(
          unscheduled_session,
          today_session,
          scheduled_session
        )
      end
    end

    describe "#completed" do
      subject(:scope) { described_class.completed }

      it { should contain_exactly(completed_session) }

      context "for a different academic year" do
        let(:completed_session) do
          create(:session, :completed, programme:, date: Date.new(2023, 9, 1))
        end

        it { should_not include(completed_session) }
      end
    end
  end

  describe "#open?" do
    subject(:open?) { session.open? }

    let(:session) { build(:session) }

    it { should be(true) }

    context "with a closed session" do
      let(:session) { build(:session, :closed) }

      it { should be(false) }
    end
  end

  describe "#closed?" do
    subject(:closed?) { session.closed? }

    let(:session) { build(:session) }

    it { should be(false) }

    context "with a closed session" do
      let(:session) { build(:session, :closed) }

      it { should be(true) }
    end
  end

  describe "#today?" do
    subject(:today?) { session.today? }

    context "when the session is scheduled for today" do
      let(:session) { create(:session, :today) }

      it { should be(true) }
    end

    context "when the session is scheduled in the past" do
      let(:session) { create(:session, :completed) }

      it { should be(false) }
    end

    context "when the session is scheduled in the future" do
      let(:session) { create(:session, :scheduled) }

      it { should be(false) }
    end
  end

  describe "#unscheduled?" do
    subject(:unscheduled?) { session.unscheduled? }

    let(:session) { create(:session, date: nil) }

    it { should be(true) }

    context "with a date" do
      before { create(:session_date, session:) }

      it { should be(false) }
    end
  end

  describe "#year_groups" do
    subject(:year_groups) { session.year_groups }

    let(:flu_programme) { create(:programme, :flu) }
    let(:hpv_programme) { create(:programme, :hpv) }

    let(:session) do
      create(:session, programmes: [flu_programme, hpv_programme])
    end

    it { should contain_exactly(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11) }
  end

  describe "#today_or_future_dates" do
    subject(:today_or_future_dates) do
      travel_to(today) { session.today_or_future_dates }
    end

    let(:dates) do
      [Date.new(2024, 1, 1), Date.new(2024, 1, 2), Date.new(2024, 1, 3)]
    end

    let(:session) { create(:session, academic_year: 2023, date: nil) }

    before { dates.each { |value| create(:session_date, session:, value:) } }

    context "on the first day" do
      let(:today) { dates.first }

      it { should match_array(dates) }
    end

    context "on the second day" do
      let(:today) { dates.second }

      it { should match_array(dates.drop(1)) }
    end

    context "on the third day" do
      let(:today) { dates.third }

      it { should match_array(dates.drop(2)) }
    end

    context "after the session" do
      let(:today) { dates.third + 1.day }

      it { should be_empty }
    end
  end

  describe "#close_consent_at" do
    subject(:close_consent_at) { session.close_consent_at }

    let(:date) { nil }

    let(:session) { create(:session, date:) }

    it { should be_nil }

    context "with a date" do
      let(:date) { Date.new(2020, 1, 2) }

      it { should eq(Date.new(2020, 1, 1)) }
    end

    context "with two dates" do
      let(:date) { Date.new(2020, 1, 2) }

      before { create(:session_date, session:, value: date + 1.day) }

      it { should eq(Date.new(2020, 1, 2)) }
    end
  end

  describe "#create_patient_sessions!" do
    subject(:create_patient_sessions!) { session.create_patient_sessions! }

    let(:flu_programme) { create(:programme, :flu) }
    let(:hpv_programme) { create(:programme, :hpv) }

    let(:school) { create(:location, :primary) }

    let!(:unvaccinated_child) do
      create(:patient, date_of_birth: 9.years.ago.to_date, team:, school:)
    end
    let!(:unvaccinated_teen) do
      create(:patient, date_of_birth: 14.years.ago.to_date, team:, school:)
    end

    let!(:flu_vaccinated_child) do
      create(
        :patient,
        :vaccinated,
        date_of_birth: 9.years.ago.to_date,
        team:,
        school:,
        programme: flu_programme
      )
    end
    let!(:flu_vaccinated_teen) do
      create(
        :patient,
        :vaccinated,
        date_of_birth: 14.years.ago.to_date,
        team:,
        school:,
        programme: flu_programme
      )
    end
    let!(:hpv_vaccinated_teen) do
      create(
        :patient,
        :vaccinated,
        date_of_birth: 14.years.ago.to_date,
        team:,
        school:,
        programme: hpv_programme
      )
    end

    let!(:both_vaccinated_teen) do
      create(:patient, date_of_birth: 14.years.ago.to_date, team:, school:)
    end

    before do
      create(
        :vaccination_record,
        programme: flu_programme,
        patient: both_vaccinated_teen
      )
      create(
        :vaccination_record,
        programme: hpv_programme,
        patient: both_vaccinated_teen
      )

      create(
        :patient,
        :deceased,
        date_of_birth: 9.years.ago.to_date,
        team:,
        school:
      )
    end

    context "with a Flu session" do
      let(:team) { create(:team, programmes: [flu_programme]) }
      let(:session) do
        create(:session, team:, location: school, programmes: [flu_programme])
      end

      it "adds the unvaccinated patients" do
        create_patient_sessions!

        expect(session.patients).to contain_exactly(
          unvaccinated_child,
          unvaccinated_teen,
          hpv_vaccinated_teen
        )
      end

      it "is idempotent" do
        expect { 2.times { create_patient_sessions! } }.not_to raise_error
      end
    end

    context "with an HPV session" do
      let(:team) { create(:team, programmes: [hpv_programme]) }
      let(:session) do
        create(:session, team:, location: school, programmes: [hpv_programme])
      end

      it "adds the unvaccinated patients" do
        create_patient_sessions!

        expect(session.patients).to contain_exactly(
          unvaccinated_teen,
          flu_vaccinated_teen
        )
      end

      it "is idempotent" do
        expect { 2.times { create_patient_sessions! } }.not_to raise_error
      end
    end

    context "with a Flu and HPV session" do
      let(:team) { create(:team, programmes: [flu_programme, hpv_programme]) }
      let(:session) do
        create(
          :session,
          team:,
          location: school,
          programmes: [flu_programme, hpv_programme]
        )
      end

      it "adds the unvaccinated patients" do
        create_patient_sessions!

        expect(session.patients).to contain_exactly(
          unvaccinated_child,
          unvaccinated_teen,
          flu_vaccinated_child,
          hpv_vaccinated_teen,
          flu_vaccinated_teen
        )
      end

      it "is idempotent" do
        expect { 2.times { create_patient_sessions! } }.not_to raise_error
      end
    end
  end
end
