# frozen_string_literal: true

class AppImportErrorsComponent < ViewComponent::Base
  erb_template <<-ERB
    <div data-qa="import-errors">
      <% @errors.each do |error| %>
        <h2 class="nhsuk-heading-s nhsuk-u-margin-bottom-2"
            data-qa="import-errors__heading">
          <% if error.attribute == :csv %>
            CSV
          <% else %>
            <%= error.attribute.to_s.humanize %>
          <% end %>
        </h2>

        <ul class="nhsuk-list nhsuk-list--bullet nhsuk-u-font-size-16"
            data-qa="import-errors__list">
          <% if error.type.is_a?(Array) %>
            <% error.type.each do |type| %>
              <li><%= sanitize type %></li>
            <% end %>
          <% else %>
            <li><%= sanitize error.type %></li>
          <% end %>
        </ul>
      <% end %>
    </div>
  ERB

  def initialize(errors)
    super

    @errors = errors
  end

  def render?
    @errors.present?
  end
end
