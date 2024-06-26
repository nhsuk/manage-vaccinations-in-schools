# frozen_string_literal: true

class AppCountComponent < ViewComponent::Base
  erb_template <<-ERB
    <span class="app-count">
      <span class="nhsuk-u-visually-hidden">(</span>
      <%= @count %>
      <span class="nhsuk-u-visually-hidden">)</span>
    </span>
  ERB

  def initialize(count:)
    super

    @count = count
  end
end
