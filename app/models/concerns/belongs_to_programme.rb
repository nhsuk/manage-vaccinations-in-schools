# frozen_string_literal: true

module BelongsToProgramme
  extend ActiveSupport::Concern

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

  def programme
    if (type = programme_type)
      # We don't pass both `patient` and `disease_types`, in case the patient
      # is eligible for a particular programme variant, but the
      # specified `disease_types` indicate a different variant.
      if respond_to?(:disease_types)
        Programme.find(type, disease_types:)
      elsif respond_to?(:patient)
        Programme.find(type, patient:)
      else
        Programme.find(type)
      end
    end
  end

  def programme=(value)
    self.programme_type = value&.type
  end

  delegate :translation_key, to: :programme, prefix: true
end
