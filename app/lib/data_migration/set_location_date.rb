# frozen_string_literal: true

class DataMigration::SetLocationDate
  def call
    GillickAssessment
      .includes(session_date: :session)
      .find_each do |gillick_assessment|
        location_id = gillick_assessment.session_date.session.location_id
        date = gillick_assessment.session_date.value
        gillick_assessment.update_columns(location_id:, date:)
      end

    PreScreening
      .includes(session_date: :session)
      .find_each do |pre_screening|
        location_id = pre_screening.session_date.session.location_id
        date = pre_screening.session_date.value
        pre_screening.update_columns(location_id:, date:)
      end
  end

  def self.call(...) = new(...).call

  private_class_method :new
end
