# frozen_string_literal: true

##
class AppAttachedTagsComponent < ViewComponent::Base
  ##
  # Renders a set of attached tags.
  #
  # `items` is expected to be a hash mapping a string (used for the attached
  # tag) to a hash containing the following keys: `text`, `colour` and
  # `details_text`.
  def initialize(items)
    @items = items
  end

  def call
    safe_join(
      items.map do |attached, hash|
        status_tag(attached, hash[:text], hash[:colour], hash[:details_text])
      end
    )
  end

  private

  attr_reader :items

  def status_tag(attached, text, colour, details_text)
    attached_tag =
      tag.strong(
        attached,
        class: "nhsuk-tag app-tag--attached nhsuk-tag--white"
      )

    main_tag = tag.strong(text, class: "nhsuk-tag nhsuk-tag--#{colour}")

    details_span =
      if details_text.present?
        tag.span(details_text, class: "nhsuk-u-secondary-text-colour")
      end

    tag.p(safe_join([attached_tag, main_tag, details_span].compact))
  end
end
