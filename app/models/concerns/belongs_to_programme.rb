# frozen_string_literal: true

module BelongsToProgramme
  extend ActiveSupport::Concern

  included { belongs_to :programme }

  def programme=(programme)
    super
    self.programme_type = programme&.type
  end
end
