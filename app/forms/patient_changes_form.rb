# frozen_string_literal: true

class PatientChangesForm
  include ActiveModel::Model

  attr_accessor :patient, :apply_changes

  validates :apply_changes, inclusion: { in: %w[apply discard] }

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      if apply_changes == "apply"
        patient.apply_pending_changes!
      elsif apply_changes == "discard"
        patient.discard_pending_changes!
      end
    end

    true
  rescue ActiveRecord::RecordInvalid
    errors.add(:base, "Failed to save changes")
    false
  end
end
