# frozen_string_literal: true

module Stats
  class ConsentBySchool
    attr_reader :programme, :organisation

    def initialize(ods_code: "RYG", programme_type: "hpv")
      @organisation = Organisation.find_by(ods_code:)
      @programme = Programme.find_by(type: programme_type)
    end

    def sessions
      @sessions ||=
        Session.where(organisation: @organisation).eager_load(:location)
    end

    def by_days_sessions
      sessions.where.not(send_consent_requests_at: nil)
    end

    def by_date_data
      collect_data if @by_date_data.blank?
      @by_date_data
    end

    def by_days_data
      collect_data if @by_days_data.blank?
      @by_days_data
    end

    def collect_data
      @by_date_data = {}
      @by_days_data = {}

      sessions.find_each do |session|
        session
          .patient_sessions
          .includes(patient: { consents: %i[consent_form parent] })
          .find_each do |patient_session|
            consent =
              patient_session.latest_consents(programme:).min_by(&:created_at)
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

    def by_date_csv
      CSV.generate do |csv|
        csv << [""] + sessions.map { _1.location.name }
        csv << ["Cohort"] + sessions.map { _1.patients.count }

        by_date_data.keys.sort.each do |date|
          csv << [date.iso8601] +
            sessions.map { by_date_data[date].fetch(_1.location, 0) }
        end
      end
    end

    def by_days_csv
      CSV.generate do |csv|
        csv << [""] + by_days_sessions.map { _1.location.name }
        csv << ["Cohort"] + by_days_sessions.map { _1.patients.count }
        csv << ["Date consent requests sent"] +
          by_days_sessions.map(&:send_consent_requests_at).map(&:iso8601)

        by_days_data.keys.sort.each do |day|
          csv << [day] +
            by_days_sessions.map { by_days_data[day].fetch(_1.location, 0) }
        end
      end
    end
  end
end
