# frozen_string_literal: true

class PatientMergeForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :current_user, :patient

  attribute :nhs_number, :string

  validates :nhs_number, nhs_number: true

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
