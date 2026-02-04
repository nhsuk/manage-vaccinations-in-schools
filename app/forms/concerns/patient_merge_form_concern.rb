# frozen_string_literal: true

module PatientMergeFormConcern
  extend ActiveSupport::Concern

  include ActiveModel::Model
  include ActiveModel::Attributes

  included do
    attribute :nhs_number, :string

    def nhs_number=(value)
      super(value.presence&.gsub(/\s/, ""))
    end
  end

  def existing_patient
    return if nhs_number.blank?

    @existing_patient ||=
      find_existing(patient_policy_scope) ||
        find_existing(Patient.where.missing(:patient_locations))
  end

  def find_existing(scope)
    scope
      .where.not(id: patient.id)
      .includes(:vaccination_records)
      .find_by(nhs_number: nhs_number)
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
