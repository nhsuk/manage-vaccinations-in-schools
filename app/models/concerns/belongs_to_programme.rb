# frozen_string_literal: true

module BelongsToProgramme
  extend ActiveSupport::Concern

  included do
    belongs_to :programme

    scope :where_programme, -> { where(programme_type: it.type) }
  end

  def programme=(programme)
    super
    self.programme_type = programme&.type
  end
end
