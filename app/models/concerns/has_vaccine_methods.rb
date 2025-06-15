# frozen_string_literal: true

module HasVaccineMethods
  extend ActiveSupport::Concern

  included do
    extend ArrayEnum

    array_enum vaccine_methods: { injection: 0, nasal: 1 }

    validates :vaccine_methods, subset: %w[injection nasal]
  end
end
