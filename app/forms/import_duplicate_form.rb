# frozen_string_literal: true

class ImportDuplicateForm
  include ActiveModel::Model

  attr_accessor :object, :apply_changes

  validates :apply_changes, inclusion: { in: :apply_changes_options }

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      case apply_changes
      when "apply"
        apply_pending_changes!
      when "discard"
        discard_pending_changes!
      when "keep_both"
        keep_both_changes!
      end
    end

    true
  rescue ActiveRecord::RecordInvalid
    errors.add(:base, "Failed to save changes")
    false
  end

  def can_keep_both?
    # Vaccination records have lots of relationships that make it difficult to handle
    object.is_a?(Patient)
  end

  def apply_changes_options
    can_keep_both? ? %w[apply discard keep_both] : %w[apply discard]
  end

  def apply_pending_changes!
    object.patient.apply_pending_changes! if object.respond_to?(:patient)

    object.apply_pending_changes!
  end

  def discard_pending_changes!
    object.patient.discard_pending_changes! if object.respond_to?(:patient)

    object.discard_pending_changes!
  end

  def keep_both_changes!
    object.apply_pending_changes_to_new_record! if can_keep_both?
  end
end
