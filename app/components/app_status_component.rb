# frozen_string_literal: true

class AppStatusComponent < ViewComponent::Base
  erb_template <<-ERB
    <p class="app-status app-status--<%= @colour %> <% if @small %>app-status--small<% end %> <%= @classes %>">
      <svg class="nhsuk-icon nhsuk-icon--warning" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="16" height="16" focusable="false" aria-hidden="true">
        <path d="M12 2a10 10 0 1 1 0 20 10 10 0 0 1 0-20Zm0 14a1.5 1.5 0 1 0 0 3 1.5 1.5 0 0 0 0-3Zm-1.5-9.5V13a1.5 1.5 0 0 0 3 0V6.5a1.5 1.5 0 0 0-3 0Z"/>
      </svg>
      <%= @text %>
    </p>
  ERB

  def initialize(text:, colour: "blue", small: false, classes: "")
    @text = text
    @colour = colour
    @small = small
    @classes = classes
  end
end
