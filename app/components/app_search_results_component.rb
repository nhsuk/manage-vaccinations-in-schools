# frozen_string_literal: true

class AppSearchResultsComponent < ViewComponent::Base
  erb_template <<-ERB
    <h3 class="nhsuk-heading-m nhsuk-u-margin-bottom-2">Search results</h3>

    <p class="nhsuk-caption-m nhsuk-u-margin-bottom-4">
      <% if has_results? %>
        Showing <b><%= pagy.from %></b> to <b><%= pagy.to %></b> of <b><%= pagy.count %></b> children
      <% else %>
        No children matching search criteria found
      <% end %>
    </p>

    <%= content %>

    <% if has_results? %>
      <%= govuk_pagination(pagy:) %>
    <% end %>
  ERB

  def initialize(pagy)
    super

    @pagy = pagy
  end

  private

  attr_reader :pagy

  def has_results? = pagy.count.positive?
end
