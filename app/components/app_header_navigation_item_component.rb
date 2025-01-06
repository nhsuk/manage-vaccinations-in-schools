# frozen_string_literal: true

class AppHeaderNavigationItemComponent < ViewComponent::Base
  def initialize(title, path, request_path:)
    super

    @title = title
    @path = path
    @request_path = request_path
  end

  def call
    tag.li(class: classes) do
      link_to(
        @title,
        @path,
        class: "nhsuk-header__navigation-link",
        aria: {
          current: current? ? "true" : nil
        }
      )
    end
  end

  def current?
    @request_path.starts_with?(@path)
  end

  def classes
    [
      "nhsuk-header__navigation-item",
      ("app-header__navigation-item--current" if current?)
    ].compact.join(" ")
  end
end
