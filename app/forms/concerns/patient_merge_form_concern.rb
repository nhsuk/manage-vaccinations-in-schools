# frozen_string_literal: true

module PatientMergeFormConcern
  extend ActiveSupport::Concern

  include ActiveModel::Model
  include ActiveModel::Attributes

  included do
    attribute :nhs_number, :string

    def nhs_number=(value)
      super(value.blank? ? nil : value.gsub(/\s/, ""))
    end
  end

  def existing_patient
    @existing_patient ||=
      if nhs_number.present?
        patient_policy_scope.includes(vaccination_records: :programme).find_by(
          nhs_number:
        ) ||
          Patient
            .where
            .missing(:patient_locations)
            .includes(vaccination_records: :programme)
            .find_by(nhs_number:)
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
