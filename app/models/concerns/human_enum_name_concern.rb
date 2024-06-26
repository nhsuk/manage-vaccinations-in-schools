# frozen_string_literal: true

module HumanEnumNameConcern
  extend ActiveSupport::Concern

  included do
    def human_enum_name(attribute)
      enum_name = attribute.to_s.pluralize
      enum_value = self[attribute]
      self.class.human_enum_name(enum_name, enum_value)
    end
  end

  class_methods do
    def human_enum_name(enum_name, enum_value)
      return "" if enum_value.blank?

      enum_i18n_key = enum_name.to_s.pluralize
      I18n.t(
        "activerecord.attributes.#{model_name.i18n_key}.#{enum_i18n_key}.#{enum_value}",
        default: ->(_key) { enum_value.to_s.humanize }
      )
    end
  end
end
