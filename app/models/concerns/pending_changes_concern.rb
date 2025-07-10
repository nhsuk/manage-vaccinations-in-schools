# frozen_string_literal: true

module PendingChangesConcern
  extend ActiveSupport::Concern

  included { attribute :pending_changes, :jsonb, default: {} }

  def stage_changes(attributes)
    new_pending_changes =
      attributes.each_with_object({}) do |(attr, new_value), staged_changes|
        current_value = public_send(attr)
        normalised_new_value =
          current_value.is_a?(Date) ? new_value.to_date : new_value

        if normalised_new_value != current_value
          staged_changes[attr.to_s] = new_value
        end
      end

    if new_pending_changes.any?
      self.pending_changes = pending_changes.merge(new_pending_changes)
    end
  end

  def with_pending_changes
    return self if pending_changes.blank?

    # Use `becomes` instead of `dup` or `clone` to preserve loaded associations.
    becomes(self.class).tap do |record|
      record.clear_changes_information
      pending_changes.each do |attr, value|
        record.public_send("#{attr}=", value) if record.respond_to?(attr)
      end
    end
  end

  def apply_pending_changes!
    pending_changes.each do |attr, value|
      public_send("#{attr}=", value) if respond_to?(attr)
    end
    yield(pending_changes, self) if block_given?
    discard_pending_changes!
  end

  def discard_pending_changes!
    self.pending_changes = {}
    save!
  end

  def apply_pending_changes_to_new_record!
    ActiveRecord::Base.transaction do
      new_record = dup_for_pending_changes.tap(&:apply_pending_changes!)
      yield(pending_changes, new_record) if block_given?
      discard_pending_changes!
    end
  end
end
