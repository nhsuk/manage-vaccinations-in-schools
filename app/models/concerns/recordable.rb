# frozen_string_literal: true

module Recordable
  extend ActiveSupport::Concern

  included do
    scope :draft, -> { where(recorded_at: nil) }
    scope :recorded, -> { where.not(recorded_at: nil) }
  end

  def draft?
    recorded_at.nil?
  end

  def recorded?
    recorded_at != nil
  end
end
