# frozen_string_literal: true

class AppHeaderNavigationItemComponent < ViewComponent::Base
  erb_template <<-ERB
    <li class="nhsuk-header__navigation-item">
      <%= link_to @title, @path,
                  class: "nhsuk-header__navigation-link",
                  aria: { current: current? ? "true" : nil } %>
    </li>
  ERB

  def initialize(title, path, request_path:)
    super

    @title = title
    @path = path
    @request_path = request_path
  end

  def current?
    @request_path.starts_with?(@path)
  end
end
