# frozen_string_literal: true

module Invalidatable
  extend ActiveSupport::Concern

  included do
    scope :not_invalidated, -> { where(invalidated_at: nil) }
    scope :invalidated, -> { where.not(invalidated_at: nil) }

    scope :invalidate_all,
          -> { not_invalidated.update_all(invalidated_at: Time.current) }
  end

  def invalidated?
    invalidated_at != nil
  end

  def not_invalidated?
    invalidated_at.nil?
  end

  def should_be_invalidated?
    delay_vaccination? && delay_vaccination_until.present? &&
      delay_vaccination_until < Date.current
  end
end
