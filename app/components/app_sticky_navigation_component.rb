# frozen_string_literal: true

class AppStickyNavigationComponent < ViewComponent::Base
  erb_template <<-ERB
    <div class="app-sticky-navigation" data-module="app-sticky">
      <div class="nhsuk-width-container">
        <%= content %>
      </div>
    </div>
  ERB

  def initialize
  end
end
