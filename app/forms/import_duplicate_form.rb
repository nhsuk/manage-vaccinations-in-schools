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
    if object.respond_to?(:patient)
      object.patient.apply_pending_changes! do |pending_changes, record|
        update_patient_family_associations(pending_changes, record)
      end
    end

    object.apply_pending_changes! do |pending_changes, record|
      if object.is_a?(Patient)
        update_patient_family_associations(pending_changes, record)
      end
    end
  end

  def discard_pending_changes!
    object.patient.discard_pending_changes! if object.respond_to?(:patient)

    object.discard_pending_changes!
  end

  def keep_both_changes!
    if can_keep_both?
      object.apply_pending_changes_to_new_record! do |pending_changes, new_record|
        update_patient_family_associations(pending_changes, new_record)
      end
    end
  end

  def update_patient_family_associations(pending_changes, new_record)
    family_connections =
      PatientImporter::ParentRelationshipFactory.new(
        pending_changes,
        new_record
      ).establish_family_connections
    family_connections.save!

    # If the duplicate record already has a school,
    # there's no need to create a school move.
    if new_record.school.nil?
      school_move =
        PatientImporter::SchoolMoveFactory.new(
          pending_changes,
          new_record
        ).resolve_school_move
      school_move&.confirm!
    end
  end
end
