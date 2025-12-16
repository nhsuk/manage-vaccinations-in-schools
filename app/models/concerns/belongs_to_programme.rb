# frozen_string_literal: true

module BelongsToProgramme
  extend ActiveSupport::Concern

  included do
    scope :where_programme,
          ->(programme, disease_types = nil) do
            query =
              if programme.is_a?(Array)
                where(programme_type: programme.map(&:type))
              else
                where(programme_type: programme.type)
              end

            if disease_types.present? && query.respond_to?(:with_disease_types)
              query.with_disease_types(disease_types)
            else
              query
            end
          end
  end

  def programme
    find_options = {}
    find_options[:disease_types] = disease_types if respond_to?(:disease_types)
    find_options[:patient] = patient if respond_to?(:patient)

    Programme.find(programme_type, **find_options)
  end

  def programme=(value)
    self.programme_type = value&.type
  end

  delegate :translation_key, to: :programme, prefix: true
end
