# frozen_string_literal: true

module PatientLoggingConcern
  extend ActiveSupport::Concern

  included { around_action :add_patient_id_log_tag }

  private

  def add_patient_id_log_tag(&block)
    patient_id = patient_id_for_logging.to_i
    SemanticLogger.tagged(patient_id:, &block)
  end
end
