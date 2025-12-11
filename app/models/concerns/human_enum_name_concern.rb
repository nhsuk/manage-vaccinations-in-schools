# frozen_string_literal: true

module HumanEnumNameConcern
  extend ActiveSupport::Concern

  included do
    def human_enum_name(attribute, plural_name: nil)
      plural_name ||= attribute.to_s.pluralize
      enum_value = self[attribute].presence || public_send(attribute)
      self.class.human_enum_name(plural_name, enum_value)
    end
  end

  class_methods do
    def human_enum_name(enum_name, enum_value)
      return "" if enum_value.blank?

      @human_enum_name ||= Hash.new({})

      if @human_enum_name[enum_name].key?(enum_value)
        return @human_enum_name[enum_name][enum_value]
      end

      @human_enum_name[enum_name][enum_value] = begin
        enum_i18n_key = enum_name.to_s.pluralize
        I18n.t(
          "activerecord.attributes.#{model_name.i18n_key}.#{enum_i18n_key}.#{enum_value}",
          default: ->(_key) { enum_value.to_s.humanize }
        )
      end
    end
  end
end
