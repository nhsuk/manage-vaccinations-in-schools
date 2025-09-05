# frozen_string_literal: true

module ParentsHelper
  def format_parents_with_relationships(parent_relationships)
    tag.ul(class: "nhsuk-list") do
      safe_join(
        parent_relationships.map do |parent_relationship|
          tag.li { format_parent_with_relationship(parent_relationship) }
        end
      )
    end
  end

  def format_parent_with_relationship(parent_relationship, include_phone: true)
    parent = parent_relationship.parent

    [
      parent_relationship.label_with_parent,
      if (email = parent.email).present?
        tag.span(email, class: "nhsuk-u-secondary-text-colour")
      end,
      if include_phone && (phone = parent.phone).present?
        tag.span(phone, class: "nhsuk-u-secondary-text-colour")
      end
    ].compact.join(tag.br).html_safe
  end
end
