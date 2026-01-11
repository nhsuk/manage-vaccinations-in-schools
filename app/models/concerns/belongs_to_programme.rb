# frozen_string_literal: true

module BelongsToProgramme
  extend ActiveSupport::Concern

  include Programmable

  included do
    scope :for_programme,
          ->(programme) do
            scope = where(programme_type: programme.type)

            if scope.respond_to?(:with_disease_types)
              scope = scope.with_disease_types(programme.disease_types)
            end

            scope
          end

    scope :for_programmes,
          ->(programmes) do
            return all if programmes.empty?

            scope = for_programme(programmes.first)

            programmes
              .drop(1)
              .reduce(scope) do |scope, programme|
                scope.or(for_programme(programme))
              end
          end
  end
end
