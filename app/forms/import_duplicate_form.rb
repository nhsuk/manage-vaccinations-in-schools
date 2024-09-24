# frozen_string_literal: true

class ImportDuplicateForm
  include ActiveModel::Model

  attr_accessor :object, :apply_changes

  validates :apply_changes, inclusion: { in: %w[apply discard] }

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      if apply_changes == "apply"
        apply_pending_changes!
      elsif apply_changes == "discard"
        discard_pending_changes!
      end
    end

    true
  rescue ActiveRecord::RecordInvalid
    errors.add(:base, "Failed to save changes")
    false
  end

  def apply_pending_changes!
    object.patient.apply_pending_changes! if object.respond_to?(:patient)

    object.apply_pending_changes!
  end

  def discard_pending_changes!
    object.patient.discard_pending_changes! if object.respond_to?(:patient)

    object.discard_pending_changes!
  end
end
