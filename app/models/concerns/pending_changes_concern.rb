# frozen_string_literal: true

module PendingChangesConcern
  extend ActiveSupport::Concern

  included { attribute :pending_changes, :jsonb, default: {} }

  def stage_changes(attributes)
    attributes.each do |attr, new_value|
      current_value = public_send(attr)

      if normalised(new_value) == normalised(current_value)
        public_send("#{attr}=", new_value)
        pending_changes.delete(attr.to_s)
      else
        pending_changes[attr.to_s] = new_value
      end
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

  def apply_pending_changes_to_new_record!
    ActiveRecord::Base.transaction do
      new_record = dup_for_pending_changes.tap(&:apply_pending_changes!)
      discard_pending_changes!
      new_record
    end
  end

  private

  def normalised(value)
    value.respond_to?(:downcase) ? value.downcase : value
  end
end
