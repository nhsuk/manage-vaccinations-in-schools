# frozen_string_literal: true

module ParentsHelper
  def format_parent(parent, patient:)
    [
      parent.label_to(patient:),
      if (email = parent.email).present?
        tag.span(email, class: "nhsuk-u-secondary-text-color")
      end,
      if (phone = parent.phone).present?
        tag.span(phone, class: "nhsuk-u-secondary-text-color")
      end
    ].compact.join(tag.br).html_safe
  end
end
