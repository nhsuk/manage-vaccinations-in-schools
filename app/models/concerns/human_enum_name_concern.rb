# frozen_string_literal: true

module HumanEnumNameConcern
  extend ActiveSupport::Concern

  included do
    def human_enum_name(attribute)
      enum_value = self[attribute].presence || public_send(attribute)
      self.class.human_enum_name(attribute, enum_value)
    end
  end

  class_methods do
    def human_enum_name(attribute, enum_value)
      return "" if enum_value.blank?

      @human_enum_name ||= {}
      @human_enum_name[attribute] ||= {}
      @human_enum_name[attribute][enum_value] ||= begin
        @enum_i18n_keys ||= {}
        enum_i18n_key =
          (@enum_i18n_keys[attribute] ||= attribute.to_s.pluralize)

        I18n.t(
          "activerecord.attributes.#{model_name.i18n_key}.#{enum_i18n_key}.#{enum_value}",
          default: ->(_key) { enum_value.to_s.humanize }
        )
      end
    end
  end
end
