# frozen_string_literal: true

module Invalidatable
  extend ActiveSupport::Concern

  included do
    scope :not_invalidated, -> { where(invalidated_at: nil) }
    scope :invalidated, -> { where.not(invalidated_at: nil) }
  end

  def invalidated?
    invalidated_at != nil
  end

  def not_invalidated?
    invalidated_at.nil?
  end
end
