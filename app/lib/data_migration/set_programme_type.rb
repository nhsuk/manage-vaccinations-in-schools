# frozen_string_literal: true

class DataMigration::SetProgrammeType
  def call
    update_single_column_models!
    update_array_column_models!
    update_notify_log_entries!
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  def single_column_models
    [
      ConsentFormProgramme,
      Consent,
      GillickAssessment,
      Location::ProgrammeYearGroup,
      Patient::ConsentStatus,
      PatientSpecificDirection,
      Patient::TriageStatus,
      Patient::VaccinationStatus,
      PreScreening,
      Triage,
      VaccinationRecord,
      Vaccine
    ]
  end

  def update_single_column_models!
    single_column_models.each do |model_class|
      model_class
        .where(programme_type: nil)
        .joins(:programme)
        .update_all("programme_type = programmes.type::programme_type")
    end
  end

  def array_column_models
    [ConsentNotification, Team, Session]
  end

  def update_array_column_models!
    array_column_models.each do |model_class|
      model_class
        .where(programme_types: nil)
        .includes(:programmes)
        .find_each do |model_instance|
          programme_types = model_instance.programmes.map(&:type).sort
          model_instance.update_columns(programme_types:)
        end
    end
  end

  def update_notify_log_entries!
    programme_types_by_id = Programme.pluck(:id, :type).to_h

    NotifyLogEntry
      .where(programme_types: nil)
      .find_each do |notify_log_entry|
        programme_types =
          notify_log_entry.programme_ids.map { programme_types_by_id.fetch(it) }
        notify_log_entry.update_columns(programme_types:)
      end
  end
end
