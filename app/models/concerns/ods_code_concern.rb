# frozen_string_literal: true

module ODSCodeConcern
  extend ActiveSupport::Concern

  included do
    validates :ods_code, uniqueness: true, allow_nil: true

    normalizes :ods_code, with: -> { it.blank? ? nil : it.upcase.strip }
  end
end
