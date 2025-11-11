# frozen_string_literal: true

module HasManyProgrammes
  extend ActiveSupport::Concern

  included do
    scope :has_all_programme_types_of,
          ->(values) do
            where(
              "#{table_name}.programme_types @> ARRAY[?]::programme_type[]",
              values
            )
          end

    scope :has_any_programme_types_of,
          ->(values) do
            where(
              "#{table_name}.programme_types && ARRAY[?]::programme_type[]",
              values
            )
          end

    scope :has_all_programmes_of,
          ->(programmes) { has_all_programme_types_of(programmes.map(&:type)) }

    scope :has_any_programmes_of,
          ->(programmes) { has_any_programme_types_of(programmes.map(&:type)) }
  end

  def programmes
    programme_types.map { Programme.new(type: it) }
  end

  def programmes=(value)
    self.programme_types = value.map(&:type).sort.uniq
  end

  def vaccines
    @vaccines ||= Vaccine.where(programme_type: programme_types)
  end
end
