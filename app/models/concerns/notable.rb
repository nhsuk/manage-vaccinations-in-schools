# frozen_string_literal: true

module Notable
  extend ActiveSupport::Concern

  included do
    encrypts :notes if respond_to?(:encrypts)

    validates :notes,
              length: {
                maximum: 1000
              },
              presence: {
                if: :requires_notes?
              }
  end

  def requires_notes? = false
end
