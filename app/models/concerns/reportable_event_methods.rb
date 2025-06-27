module ReportableEventMethods
  extend ActiveSupport::Concern

  included do
    belongs_to :source, polymorphic: true
    belongs_to :patient

    before_validation :set_event_timestamp_date_part_attributes, :set_patient_year_group

    protected

    def set_patient_year_group
      self.patient_year_group = self.patient&.year_group(now: self.event_timestamp&.to_date)
    end

    def set_event_timestamp_date_part_attributes
      self.event_timestamp_day = event_timestamp&.day
      self.event_timestamp_month = event_timestamp&.month
      self.event_timestamp_year = event_timestamp&.year

      self.event_timestamp_academic_year = event_timestamp.to_date.academic_year
    end
  end
end