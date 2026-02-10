# frozen_string_literal: true

module EthnicityHelper
  def format_ethnic_group_and_background(record)
    group_label = I18n.t("ethnicity.groups.#{record.ethnic_group}")
    background_label =
      I18n.t("ethnicity.backgrounds.#{record.ethnic_background}")

    background_with_additional = [
      background_label,
      record.ethnic_background_other
    ].compact_blank.join(" - ")

    if group_label.present? && background_with_additional.present?
      "#{group_label} (#{background_with_additional})"
    end
  end
end
