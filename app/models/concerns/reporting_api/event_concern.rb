# frozen_string_literal: true

module ReportingAPI::EventConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :source, polymorphic: true
    belongs_to :patient

    before_validation :set_patient_from_source,
                      :set_event_timestamp_date_part_attributes,
                      :set_patient_year_group

    protected

    def set_patient_from_source
      self.patient = source.try(:patient)
    end

    def set_patient_year_group
      self.patient_year_group =
        patient.year_group(academic_year: event_timestamp.to_date.academic_year)
    end

    def set_event_timestamp_date_part_attributes
      self.event_timestamp_day = event_timestamp.day
      self.event_timestamp_month = event_timestamp.month
      self.event_timestamp_year = event_timestamp.year

      self.event_timestamp_academic_year = event_timestamp.to_date.academic_year
    end

    def self.count_sql_where(comparison:, as:)
      "SUM(CASE WHEN #{comparison} THEN 1 ELSE 0 END) AS #{as}"
    end
  end
end
