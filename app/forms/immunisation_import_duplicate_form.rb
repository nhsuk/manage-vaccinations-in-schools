# frozen_string_literal: true

class ImmunisationImportDuplicateForm
  include ActiveModel::Model

  attr_accessor :vaccination_record, :apply_changes

  validates :apply_changes, inclusion: { in: %w[apply discard] }

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      if apply_changes == "apply"
        vaccination_record.patient.apply_pending_changes!
        vaccination_record.apply_pending_changes!
      elsif apply_changes == "discard"
        vaccination_record.patient.discard_pending_changes!
        vaccination_record.discard_pending_changes!
      end
    end

    true
  rescue ActiveRecord::RecordInvalid
    errors.add(:base, "Failed to save changes")
    false
  end
end
