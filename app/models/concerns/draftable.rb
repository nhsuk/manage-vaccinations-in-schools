# frozen_string_literal: true

module Draftable
  extend ActiveSupport::Concern

  included do
    scope :active, -> { where(active: true) }
    scope :draft, -> { where(active: false) }
  end

  def draft?
    !active
  end
end
