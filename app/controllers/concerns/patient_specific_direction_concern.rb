# frozen_string_literal: true

module PatientSpecificDirectionConcern
  extend ActiveSupport::Concern

  def patient_sessions_allowed_psd
    @patient_sessions_allowed_psd ||=
      @session
        .patient_sessions
        .has_consent_status(:given, programme:)
        .without_patient_specific_direction(programme:)
  end
end
