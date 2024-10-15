# frozen_string_literal: true

class AppImportErrorsComponent < ViewComponent::Base
  erb_template <<-ERB
    <div class="nhsuk-card nhsuk-card--feature app-card--red">
      <div class="nhsuk-card__content nhsuk-card__content--feature">
        <h2 class="nhsuk-card__heading nhsuk-card__heading--feature nhsuk-heading-m">
          Records could not be imported
        </h2>

        <p class="nhsuk-u-reading-width">
          The records cannot be uploaded due to errors in the CSV file.
          When fixing these errors, note that the header does not count as a row.
        </p>

        <div data-qa="import-errors">
          <% @errors.each do |error| %>
            <h3 class="nhsuk-heading-s" data-qa="import-errors__heading">
              <% if error.attribute == :csv %>
                CSV
              <% else %>
                <%= error.attribute.to_s.humanize %>
              <% end %>
            </h3>

            <ul class="nhsuk-list nhsuk-list--bullet"
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
      </div>
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
