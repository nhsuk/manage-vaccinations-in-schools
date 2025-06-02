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
    if can_keep_both?
      new_record = object.apply_pending_changes_to_new_record!

      if twins?(object, new_record)
        # When handling twin records, we need to ensure school moves
        # are correctly assigned:
        # 1. Remove the school move from the original patient record
        #    because it was added during the duplicate detection process
        #    when importing the second twin
        # 2. Confirm the school move on the new twin record to ensure it's
        #    properly assigned to the correct school.
        # This prevents both twins from being incorrectly assigned to the same school
        # and ensures each twin's school assignment reflects their actual situation.
        find_latest_school_move(object)&.destroy!
        find_latest_school_move(new_record)&.confirm!
      end

      new_record
    end
  end

  def find_latest_school_move(patient)
    patient
      .school_moves
      .includes(:organisation, :school)
      .order(created_at: :desc)
      .limit(1)
      .first
  end

  def twins?(patient, new_record)
    patient.date_of_birth == new_record.date_of_birth &&
      patient.family_name == new_record.family_name &&
      patient.address_postcode == new_record.address_postcode
  end
end
