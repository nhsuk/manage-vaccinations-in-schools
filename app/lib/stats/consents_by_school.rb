# frozen_string_literal: true

module Stats
  class ConsentsBySchool
    def initialize(teams:, programmes:, academic_year:)
      @teams = teams
      @programmes = programmes
      @academic_year = academic_year
    end

    def call
      collect_data

      { by_date: @by_date_data, by_days: @by_days_data, sessions: sessions }
    end

    private

    attr_reader :teams, :programmes, :academic_year

    def sessions
      @sessions ||=
        Session
          .joins(:session_programmes)
          .where(
            team: @teams,
            academic_year: @academic_year,
            session_programmes: {
              programme: @programmes
            }
          )
          .eager_load(:location, session_programmes: :programme)
          .where.not(send_consent_requests_at: nil)
    end

    def collect_data
      @by_date_data = {}
      @by_days_data = {}

      sessions.find_each do |session|
        session
          .patient_sessions
          .includes(patient: { consents: %i[consent_form parent] })
          .find_each do |patient_session|
            @programmes.each do |programme|
              consent =
                ConsentGrouper.call(
                  patient_session.patient.consents,
                  programme_id: programme.id,
                  academic_year: @academic_year
                )&.min_by(&:created_at)

              next if consent.nil?

              days =
                (
                  consent.responded_at.to_date -
                    session.send_consent_requests_at
                ).to_i

              @by_days_data[days] ||= {}
              @by_days_data[days][[session.location.id, programme.id]] ||= 0
              @by_days_data[days][[session.location.id, programme.id]] += 1

              @by_date_data[consent.responded_at.to_date] ||= {}
              @by_date_data[consent.responded_at.to_date][
                [session.location.id, programme.id]
              ] ||= 0
              @by_date_data[consent.responded_at.to_date][
                [session.location.id, programme.id]
              ] += 1
            end
          end
      end
    end
  end
end
