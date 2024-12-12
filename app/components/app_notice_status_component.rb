# frozen_string_literal: true

class AppNoticeStatusComponent < ViewComponent::Base
  def call
    icon_warning @text, "blue"
  end

  def initialize(text:)
    super

    @text = text
  end

  private

  def icon_warning(content, color)
    template = <<-ERB
      <p class="app-status app-status--#{color}">
        <svg class="nhsuk-icon app-icon__warning"
             xmlns="http://www.w3.org/2000/svg"
             viewBox="0 0 24 24"
             aria-hidden="true">
          <path d="M12 2a10 10 0 1 1 0 20 10 10 0 0 1 0-20Zm0 14a1.5 1.5 0 1 0 0 3 1.5 1.5 0 0 0 0-3Zm-1.5-9.5V13a1.5 1.5 0 0 0 3 0V6.5a1.5 1.5 0 0 0-3 0Z" fill="currentColor"></path>
        </svg>
        #{content}
      </p>
    ERB
    template.html_safe
  end
end
