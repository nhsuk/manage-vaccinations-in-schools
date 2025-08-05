# frozen_string_literal: true

module PatientMergeFormConcern
  extend ActiveSupport::Concern

  include ActiveModel::Model
  include ActiveModel::Attributes

  included { attribute :nhs_number, :string }

  def existing_patient
    @existing_patient ||=
      if nhs_number.present?
        patient_policy_scope.find_by(nhs_number:) ||
          Patient.where.missing(:patient_sessions).find_by(nhs_number:)
      end
  end

  def save
    return false if invalid?

    if existing_patient
      PatientMerger.call(to_keep: existing_patient, to_destroy: patient)
    end

    true
  end

  private

  def patient_policy_scope
    PatientPolicy::Scope.new(current_user, Patient).resolve
  end
end
