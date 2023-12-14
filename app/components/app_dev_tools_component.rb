class AppDevToolsComponent < ViewComponent::Base
  erb_template <<-ERB
    <% unless Rails.env.production? %>
      <%= govuk_details(
        summary_text: "Dev tools (only available in non-production environments)"
      ) do %>
        <%= content %>
      <% end %>
    <% end %>
  ERB

  def render?
    !Rails.env.production?
  end
end
