# frozen_string_literal: true

module PendingChangesConcern
  extend ActiveSupport::Concern

  included { attribute :pending_changes, :jsonb, default: {} }

  def stage_changes(attributes)
    new_pending_changes =
      attributes.each_with_object({}) do |(attr, new_value), staged_changes|
        current_value = public_send(attr)
        staged_changes[attr.to_s] = new_value if new_value != current_value
      end

    if new_pending_changes.any?
      update!(pending_changes: pending_changes.merge(new_pending_changes))
    end
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
end
