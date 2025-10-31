# frozen_string_literal: true

# == Schema Information
#
# Table name: sessions
#
#  id                            :bigint           not null, primary key
#  academic_year                 :integer          not null
#  days_before_consent_reminders :integer
#  national_protocol_enabled     :boolean          default(FALSE), not null
#  psd_enabled                   :boolean          default(FALSE), not null
#  requires_registration         :boolean          default(TRUE), not null
#  send_consent_requests_at      :date
#  send_invitations_at           :date
#  slug                          :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  location_id                   :bigint           not null
#  team_id                       :bigint           not null
#
# Indexes
#
#  index_sessions_on_academic_year_and_location_id_and_team_id  (academic_year,location_id,team_id)
#  index_sessions_on_location_id                                (location_id)
#  index_sessions_on_location_id_and_academic_year_and_team_id  (location_id,academic_year,team_id)
#  index_sessions_on_team_id_and_academic_year                  (team_id,academic_year)
#  index_sessions_on_team_id_and_location_id                    (team_id,location_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#

describe Session do
  describe "associations" do
    describe "#programmes" do
      subject(:programmes) { session.reload.programmes }

      let(:hpv_programme) { create(:programme, :hpv) }
      let(:menacwy_programme) { create(:programme, :menacwy) }

      let(:session) do
        create(:session, programmes: [menacwy_programme, hpv_programme])
      end

      it "is ordered by name" do
        expect(programmes).to eq([hpv_programme, menacwy_programme])
      end
    end
  end

  describe "scopes" do
    let(:programmes) { [create(:programme)] }

    let(:closed_session) { create(:session, :closed, programmes:) }
    let(:completed_session) { create(:session, :completed, programmes:) }
    let(:scheduled_session) { create(:session, :scheduled, programmes:) }
    let(:today_session) { create(:session, :today, programmes:) }
    let(:unscheduled_session) { create(:session, :unscheduled, programmes:) }

    describe "#has_programmes" do
      subject(:scope) { described_class.has_programmes(programmes) }

      context "with a session matching the search" do
        let(:programmes) { [create(:programme)] }
        let(:session) { create(:session, programmes:) }

        it { should include(session) }
      end

      context "with a session not matching the search" do
        let(:programmes) { [create(:programme, :hpv)] }
        let(:session) do
          create(:session, programmes: [create(:programme, :flu)])
        end

        it { should_not include(session) }
      end

      context "with a session with multiple programmes" do
        let(:programmes) do
          [create(:programme, :menacwy), create(:programme, :td_ipv)]
        end
        let(:session) { create(:session, programmes:) }

        it { should include(session) }
      end

      context "with a session with at least all the search programmes" do
        let(:session) do
          create(
            :session,
            programmes: [
              create(:programme, :hpv),
              create(:programme, :menacwy),
              create(:programme, :td_ipv)
            ]
          )
        end
        let(:programmes) { [session.programmes.first] }

        it { should include(session) }
      end
    end

    describe "#supports_delegation" do
      subject(:scope) { described_class.supports_delegation }

      let!(:hpv_programme) { create(:programme, :hpv) }
      let!(:flu_programme) { create(:programme, :flu) }
      let(:session) { create(:session, programmes:) }

      context "with a session for flu" do
        let(:programmes) { [flu_programme] }

        it { should include(session) }
      end

      context "with a session for HPV" do
        let(:programmes) { [hpv_programme] }

        it { should_not include(session) }
      end
    end

    describe "#in_progress" do
      subject(:scope) { described_class.in_progress }

      it { should contain_exactly(today_session) }
    end

    describe "#unscheduled" do
      subject(:scope) { described_class.unscheduled }

      it { should contain_exactly(unscheduled_session) }
    end

    describe "#scheduled" do
      subject(:scope) { described_class.scheduled }

      it { should contain_exactly(today_session, scheduled_session) }
    end

    describe "#completed" do
      subject(:scope) { described_class.completed }

      it { should contain_exactly(completed_session) }
    end

    describe "#order_by_earliest_date" do
      subject(:scope) { described_class.order_by_earliest_date }

      around { |example| travel_to(today) { example.run } }

      let(:today) { Date.new(2025, 1, 1) }

      let(:programmes) { create_list(:programme, 1, :hpv) }

      let(:first_session_before_today) do
        create(:session, date: Date.new(2024, 12, 1), programmes:)
      end
      let(:second_session_before_today) do
        create(:session, date: Date.new(2024, 12, 2), programmes:)
      end
      let(:session_today) do
        create(:session, date: Date.new(2025, 1, 1), programmes:)
      end
      let(:first_session_after_today) do
        create(:session, date: Date.new(2025, 1, 2), programmes:)
      end
      let(:second_session_after_today) do
        create(:session, date: Date.new(2025, 1, 3), programmes:)
      end
      let(:session_without_dates) { create(:session, date: nil, programmes:) }

      it do
        expect(scope).to eq(
          [
            session_today,
            first_session_after_today,
            second_session_after_today,
            first_session_before_today,
            second_session_before_today,
            session_without_dates
          ]
        )
      end
    end

    describe "#scheduled_for_search_in_nhs_immunisations_api" do
      subject(:scope) do
        described_class.scheduled_for_search_in_nhs_immunisations_api
      end

      let(:team) { create(:team) }
      let(:flu) { create(:programme, :flu) }

      let(:location) { create(:school, team:, programmes: [flu]) }

      context "with a normal school session" do
        let(:send_consent_requests_at) {}
        let(:days_before_consent_reminders) { 7 }

        let!(:session) do
          create(
            :session,
            programmes: [flu],
            academic_year: AcademicYear.pending,
            dates:,
            send_consent_requests_at: send_consent_requests_at,
            days_before_consent_reminders: days_before_consent_reminders,
            team:,
            location:
          )
        end

        context "with a specific unscheduled session" do
          let(:dates) { [] }
          let(:days_before_consent_reminders) { nil }

          it "does not include unscheduled sessions" do
            expect(scope).not_to include(session)
          end
        end

        context "session with dates in the future" do
          let(:dates) { [7.days.from_now] }
          let(:send_consent_requests_at) { 14.days.ago }

          it "is included" do
            expect(scope).to include(session)
          end

          context "clinic session" do
            let(:location) { create(:generic_clinic, team:, programmes: [flu]) }

            it "is included" do
              expect(scope).to include(session)
            end
          end
        end

        context "session with dates in the past",
                within_academic_year: {
                  from_start: 7.days
                } do
          let(:dates) { [7.days.ago] }
          let(:send_consent_requests_at) { 30.days.ago }

          it "is excluded" do
            expect(scope).not_to include(session)
          end
        end

        context "session with dates in the past and the future",
                within_academic_year: {
                  from_start: 7.days
                } do
          let(:send_consent_requests_at) { 28.days.ago }
          let(:dates) { [7.days.ago, 7.days.from_now] }

          it "is included" do
            expect(scope).to include(session)
          end
        end

        context "session with send_invitations_at in the future" do
          let(:location) { create(:generic_clinic, team:, programmes: [flu]) }
          let(:dates) { [17.days.from_now] }

          let!(:session) do
            create(
              :session,
              programmes: [flu],
              academic_year: AcademicYear.pending,
              dates:,
              send_invitations_at: 2.days.from_now,
              send_consent_requests_at: nil,
              days_before_consent_reminders: nil,
              team:,
              location:
            )
          end

          it "is included (within 2 days threshold)" do
            expect(scope).to include(session)
          end
        end

        context "session with send_consent_requests_at too far in the future" do
          let(:dates) { [17.days.from_now] }
          let(:send_consent_requests_at) { 3.days.from_now }

          it "is excluded" do
            expect(scope).not_to include(session)
          end
        end
      end

      shared_examples "notification date logic for scope" do |notification_date_field|
        let(:dates) { [30.days.from_now] }

        context "with notification date within threshold" do
          let!(:session) do
            session_attributes = {
              programmes: [flu],
              academic_year: AcademicYear.pending,
              dates: dates,
              team: team,
              location: location
            }

            if notification_date_field == :send_invitations_at
              session_attributes[:send_invitations_at] = 1.day.from_now
              session_attributes[:send_consent_requests_at] = nil
            else
              session_attributes[:send_invitations_at] = nil
              session_attributes[:send_consent_requests_at] = 1.day.from_now
              session_attributes[:days_before_consent_reminders] = 7
            end

            create(:session, session_attributes)
          end

          it "includes the session" do
            expect(scope).to include(session)
          end
        end

        context "with notification date too far in future" do
          let!(:session) do
            session_attributes = {
              programmes: [flu],
              academic_year: AcademicYear.pending,
              dates: dates,
              team: team,
              location: location
            }

            if notification_date_field == :send_invitations_at
              session_attributes[:send_invitations_at] = 3.days.from_now
              session_attributes[:send_consent_requests_at] = nil
            else
              session_attributes[:send_invitations_at] = nil
              session_attributes[:send_consent_requests_at] = 3.days.from_now
              session_attributes[:days_before_consent_reminders] = 7
            end

            create(:session, session_attributes)
          end

          it "excludes the session" do
            expect(scope).not_to include(session)
          end
        end
      end

      context "testing notification date logic for different location types" do
        context "generic clinic sessions" do
          let(:location) { create(:generic_clinic, team:, programmes: [flu]) }

          include_examples "notification date logic for scope",
                           :send_invitations_at
        end

        context "school sessions" do
          let(:location) { create(:school, team:, programmes: [flu]) }

          include_examples "notification date logic for scope",
                           :send_consent_requests_at
        end

        context "mixed session types" do
          let(:generic_clinic) do
            create(:generic_clinic, team:, programmes: [flu])
          end
          let(:school_location) { create(:school, team:, programmes: [flu]) }

          let!(:generic_clinic_session) do
            create(
              :session,
              programmes: [flu],
              academic_year: AcademicYear.pending,
              dates: [30.days.from_now],
              send_invitations_at: 1.day.from_now,
              send_consent_requests_at: nil,
              days_before_consent_reminders: nil,
              team: team,
              location: generic_clinic
            )
          end

          let!(:school_session) do
            create(
              :session,
              programmes: [flu],
              academic_year: AcademicYear.pending,
              dates: [30.days.from_now],
              send_invitations_at: nil,
              send_consent_requests_at: 1.day.from_now,
              days_before_consent_reminders: 7,
              team: team,
              location: school_location
            )
          end

          it "includes all sessions when their respective notification dates are within threshold" do
            expect(scope).to include(generic_clinic_session)
            expect(scope).to include(school_session)
          end
        end
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
    subject { session.reload.unscheduled? }

    let(:session) { create(:session, date: nil) }

    it { should be(true) }

    context "with a date" do
      before { create(:session_date, session:) }

      it { should be(false) }
    end
  end

  describe "#scheduled?" do
    subject { session.reload.scheduled? }

    let(:session) { create(:session, date: nil) }

    it { should be(false) }

    context "with a date" do
      before { create(:session_date, session:) }

      it { should be(true) }
    end
  end

  describe "#supports_delegation?" do
    subject { session.supports_delegation? }

    let(:session) { create(:session, programmes:) }

    context "with only a flu programme" do
      let(:programmes) { [create(:programme, :flu)] }

      it { should be(true) }
    end

    context "with a flu and HPV programme" do
      let(:programmes) { [create(:programme, :flu), create(:programme, :hpv)] }

      it { should be(true) }
    end

    context "with only an HPV programme" do
      let(:programmes) { [create(:programme, :hpv)] }

      it { should be(false) }
    end
  end

  describe "#pgd_supply_enabled?" do
    subject { session.pgd_supply_enabled? }

    let(:session) { create(:session, programmes:) }

    context "with only a flu programme" do
      let(:programmes) { [create(:programme, :flu)] }

      it { should be(true) }
    end

    context "with a flu and HPV programme" do
      let(:programmes) { [create(:programme, :flu), create(:programme, :hpv)] }

      it { should be(true) }
    end

    context "with only an HPV programme" do
      let(:programmes) { [create(:programme, :hpv)] }

      it { should be(false) }
    end
  end

  describe "#patients_with_no_consent_response_count" do
    subject(:count) { session.patients_with_no_consent_response_count }

    let(:programme) { create(:programme) }
    let(:session) { create(:session, programmes: [programme]) }

    context "when there are no patients" do
      it { should eq(0) }
    end

    context "when there are patients with different consent statuses" do
      it "returns count of patients with no response consent status" do
        create(
          :patient,
          :consent_no_response,
          session:,
          programmes: [programme]
        )
        create(
          :patient,
          :consent_given_triage_not_needed,
          session:,
          programmes: [programme]
        )

        expect(count).to eq(1)
      end
    end
  end

  describe "#year_groups" do
    subject { session.year_groups }

    let(:flu_programme) { create(:programme, :flu) }
    let(:hpv_programme) { create(:programme, :hpv) }

    let(:session) do
      create(:session, programmes: [flu_programme, hpv_programme])
    end

    it { should contain_exactly(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11) }
  end

  describe "#vaccine_methods" do
    subject { session.vaccine_methods }

    let(:flu_programme) { create(:programme, :flu) }
    let(:hpv_programme) { create(:programme, :hpv) }

    let(:session) do
      create(:session, programmes: [flu_programme, hpv_programme])
    end

    it { should contain_exactly("injection", "nasal") }
  end

  describe "#has_multiple_vaccine_methods?" do
    subject { session.has_multiple_vaccine_methods? }

    let(:session) { create(:session, programmes: [programme]) }

    context "with a flu session" do
      let(:programme) { create(:programme, :flu) }

      it { should be(true) }
    end

    context "with an HPV session" do
      let(:programme) { create(:programme, :hpv) }

      it { should be(false) }
    end
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

  describe "#scheduled_for_search_in_nhs_immunisations_api?" do
    subject(:scheduled?) do
      session.scheduled_for_search_in_nhs_immunisations_api?
    end

    let(:team) { create(:team) }
    let(:flu) { create(:programme, :flu) }
    let(:location) { create(:school, team:, programmes: [flu]) }

    let(:session) do
      create(
        :session,
        programmes: [flu],
        academic_year: AcademicYear.pending,
        dates:,
        send_consent_requests_at:,
        team:,
        location:
      )
    end

    context "when the session meets the scope criteria" do
      let(:dates) { [7.days.from_now] }
      let(:send_consent_requests_at) { 14.days.ago }

      it { should be(true) }
    end

    context "when the session does not meet the scope criteria" do
      let(:dates) { [17.days.from_now] }
      let(:send_consent_requests_at) { 3.days.from_now } # too far in the future

      it { should be(false) }
    end
  end
end
