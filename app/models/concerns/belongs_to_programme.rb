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

            if disease_types.present?
              enum_values = disease_types.map { |dt| Vaccine.disease_types[dt] }
              query.where(
                "ARRAY(SELECT unnest(disease_types) ORDER BY 1) = ARRAY[?]::integer[]",
                enum_values.sort
              )
            else
              query
            end
          end
  end

  def programme
    if (type = programme_type)
      Programme.find(type)
    end
  end

  def programme=(value)
    self.programme_type = value&.type
  end
end
