# frozen_string_literal: true

class AppNoticesTableComponent < ViewComponent::Base
  def initialize(
    deceased_patients:,
    invalidated_patients:,
    restricted_patients:,
    has_vaccination_records_dont_notify_parents_patients:
  )
    super

    @deceased_patients = deceased_patients
    @invalidated_patients = invalidated_patients
    @restricted_patients = restricted_patients
    @has_vaccination_records_dont_notify_parents_patients =
      has_vaccination_records_dont_notify_parents_patients
  end

  def render?
    @deceased_patients.present? || @invalidated_patients.present? ||
      @restricted_patients.present? ||
      @has_vaccination_records_dont_notify_parents_patients.present?
  end

  private

  def notices
    all_patients =
      (
        @deceased_patients + @invalidated_patients + @restricted_patients +
          @has_vaccination_records_dont_notify_parents_patients
      ).uniq

    notices =
      all_patients.flat_map do |patient|
        helpers
          .patient_important_notices(patient)
          .map { |notification| notification.merge(patient:) }
      end
    notices.sort_by { it[:date_time] }.reverse
  end
end
