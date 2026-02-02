# frozen_string_literal: true

class AppCardComponent::Heading < ViewComponent::Base
  def initialize(level: 3, size: nil, colour: nil, link_to: nil, actions: [])
    @level = level
    @size = size
    @colour = colour
    @link_to = link_to
    @actions = actions
  end

  def call
    if @actions.present?
      tag.div(class: "nhsuk-card__heading-container") do
        safe_join([heading, actions].compact)
      end
    else
      heading
    end
  end

  def show_in_content? = @actions.empty?

  private

  def heading
    content_tag(:"h#{@level}", class: heading_classes) do
      if @link_to.present?
        link_to(@link_to, class: "nhsuk-card__link") { content }
      else
        content
      end
    end
  end

  def actions
    tag.ul(class: "nhsuk-card__actions") do
      safe_join(
        @actions.map do |action|
          tag.li(class: "nhsuk-card__action") do
            link_to(action[:text], action[:href], class: "nhsuk-link")
          end
        end
      )
    end
  end

  def heading_modifier
    return @size if @size.present?

    if @level >= 4
      "s"
    else
      "m"
    end
  end

  def heading_classes
    [
      "nhsuk-card__heading",
      "nhsuk-heading-#{heading_modifier}",
      ("app-card__heading--#{@colour}" if @colour)
    ].compact.join(" ")
  end
end
