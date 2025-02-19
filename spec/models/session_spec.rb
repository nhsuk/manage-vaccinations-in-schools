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
#  send_invitations_at           :date
#  slug                          :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  location_id                   :bigint           not null
#  organisation_id               :bigint           not null
#
# Indexes
#
#  idx_on_organisation_id_location_id_academic_year_3496b72d0c  (organisation_id,location_id,academic_year) UNIQUE
#  index_sessions_on_organisation_id                            (organisation_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#

describe Session do
  describe "scopes" do
    let(:programme) { create(:programme) }

    let(:closed_session) { create(:session, :closed, programme:) }
    let(:completed_session) { create(:session, :completed, programme:) }
    let(:scheduled_session) { create(:session, :scheduled, programme:) }
    let(:today_session) { create(:session, :today, programme:) }
    let(:unscheduled_session) { create(:session, :unscheduled, programme:) }

    describe "#for_current_academic_year" do
      subject(:scope) { described_class.for_current_academic_year }

      it do
        expect(scope).to contain_exactly(
          unscheduled_session,
          today_session,
          scheduled_session
        )
      end
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
    subject(:unscheduled?) { session.reload.unscheduled? }

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

    let(:session) { create(:session, academic_year: 2023, dates:) }

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

      before { session.session_dates.create!(value: date + 1.day) }

      it { should eq(Date.new(2020, 1, 2)) }
    end
  end

  describe "#open_for_consent?" do
    subject(:open_for_consent?) { session.open_for_consent? }

    context "without a close consent period" do
      let(:session) { create(:session, date: nil) }

      it { should be(false) }
    end

    context "when the consent period closes today" do
      let(:session) { create(:session, date: Date.tomorrow) }

      it { should be(true) }
    end

    context "when the consent period closes tomorrow" do
      let(:session) { create(:session, date: Date.tomorrow + 1.day) }

      it { should be(true) }
    end

    context "when the consent period closed yesterday" do
      let(:session) { create(:session, date: Date.current) }

      it { should be(false) }
    end
  end
end
