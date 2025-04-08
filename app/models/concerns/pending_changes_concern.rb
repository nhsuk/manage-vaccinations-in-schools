# frozen_string_literal: true

module PendingChangesConcern
  extend ActiveSupport::Concern

  included { attribute :pending_changes, :jsonb, default: {} }

  def stage_changes(attributes)
    new_pending_changes =
      attributes.each_with_object({}) do |(attr, new_value), staged_changes|
        current_value = public_send(attr)

        # Automatically update the patient's attribute if `new_value` is the same as `current_value` except from:
        #  - whitespace
        # Otherwise, stage the change for review
        if normalise_for_comparison(new_value) ==
          normalise_for_comparison(current_value)
          public_send("#{attr}=", new_value) if new_value != current_value
        else
          staged_changes[attr.to_s] = new_value
        end
      end

    if new_pending_changes.any?
      update!(pending_changes: pending_changes.merge(new_pending_changes))
    end
  end

  def normalise_for_comparison(value)
    # Normalise whitespace
    value.respond_to?(:normalise_whitespace) ? value.normalise_whitespace : value
  end

  def with_pending_changes
    return self if pending_changes.blank?

    # Use `becomes` instead of `dup` or `clone` to preserve loaded associations.
    becomes(self.class).tap do |record|
      record.clear_changes_information
      pending_changes.each do |attr, value|
        record.public_send("#{attr}=", value)
      end
    end
  end

  def apply_pending_changes!
    pending_changes.each { |attr, value| public_send("#{attr}=", value) }
    discard_pending_changes!
  end

  def discard_pending_changes!
    self.pending_changes = {}
    save!
  end

  def apply_pending_changes_to_new_record!
    ActiveRecord::Base.transaction do
      new_record = dup_for_pending_changes.tap(&:apply_pending_changes!)
      discard_pending_changes!
      new_record
    end
  end
end
