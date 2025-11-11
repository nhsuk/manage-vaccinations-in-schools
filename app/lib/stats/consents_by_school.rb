# frozen_string_literal: true

module Stats
  class ConsentsBySchool
    def initialize(teams:, programme_types:, academic_year:)
      @teams = teams
      @programme_types = programme_types
      @academic_year = academic_year
    end

    def call
      collect_data

      {
        by_date: @by_date_data,
        by_days: @by_days_data,
        sessions: sessions,
        by_days_sessions: by_days_sessions
      }
    end

    private

    attr_reader :teams, :programme_types, :academic_year

    def sessions
      @sessions ||=
        ::Session
          .where(team: @teams, academic_year: @academic_year)
          .has_any_programme_types_of(programme_types)
          .eager_load(:location)
    end

    def by_days_sessions
      sessions.where.not(send_consent_requests_at: nil)
    end

    def collect_data
      @by_date_data = {}
      @by_days_data = {}

      sessions.find_each do |session|
        session
          .patient_locations
          .includes(patient: { consents: %i[consent_form parent] })
          .find_each do |patient_location|
            grouped_consents =
              programme_types.map do |programme_type|
                ConsentGrouper.call(
                  patient_location.patient.consents,
                  programme_type:,
                  academic_year:
                )&.min_by(&:created_at)
              end

            consents = grouped_consents.compact
            consent = consents.min_by(&:created_at)
            next if consent.nil?

            if session.send_consent_requests_at.present?
              days =
                (
                  consent.responded_at.to_date -
                    session.send_consent_requests_at
                ).to_i

              @by_days_data[days] ||= {}
              @by_days_data[days][session.location] ||= 0
              @by_days_data[days][session.location] += 1
            end

            @by_date_data[consent.responded_at.to_date] ||= {}
            @by_date_data[consent.responded_at.to_date][session.location] ||= 0
            @by_date_data[consent.responded_at.to_date][session.location] += 1
          end
      end
    end
  end
end
