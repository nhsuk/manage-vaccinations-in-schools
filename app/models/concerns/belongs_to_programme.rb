# frozen_string_literal: true

module BelongsToProgramme
  extend ActiveSupport::Concern

  included do
    self.ignored_columns = %w[programme_id]

    scope :where_programme,
          ->(value) do
            if value.is_a?(Array)
              where(programme_type: value.map(&:type))
            else
              where(programme_type: value.type)
            end
          end
  end

  def programme
    if (type = programme_type)
      Programme.new(type:)
    end
  end

  def programme=(value)
    self.programme_type = value&.type
  end
end
