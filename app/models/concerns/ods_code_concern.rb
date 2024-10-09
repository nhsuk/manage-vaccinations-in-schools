# frozen_string_literal: true

module ODSCodeConcern
  extend ActiveSupport::Concern

  included do
    validates :ods_code, uniqueness: true, allow_nil: true

    normalizes :ods_code, with: -> { _1.blank? ? nil : _1.upcase.strip }
  end
end
