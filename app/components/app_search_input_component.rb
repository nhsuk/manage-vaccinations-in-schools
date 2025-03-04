# frozen_string_literal: true

class AppSearchInputComponent < ViewComponent::Base
  erb_template <<-ERB
    <div class="app-search-input" role="search">
      <%= f.govuk_text_field :q, label: { text: "Search", class: "nhsuk-u-visually-hidden" }, autocomplete: "off", class: "app-search-input__input" %>

      <button class="nhsuk-button nhsuk-button--secondary app-button--icon app-search-input__submit" data-module="nhsuk-button" type="submit">
        <svg class="nhsuk-icon nhsuk-icon__search" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" focusable="false" role="img">
          <title>Search</title>
          <path d="M19.71 18.29l-4.11-4.1a7 7 0 1 0-1.41 1.41l4.1 4.11a1 1 0 0 0 1.42 0 1 1 0 0 0 0-1.42zM5 10a5 5 0 1 1 5 5 5 5 0 0 1-5-5z" fill="currentColor"></path>
        </svg>
      </button>
    </div>
  ERB

  def initialize(f:) # rubocop:disable Naming/MethodParameterName
    super

    @f = f
  end

  private

  attr_reader :f
end
