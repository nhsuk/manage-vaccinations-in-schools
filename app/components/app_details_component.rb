# frozen_string_literal: true

class AppDetailsComponent < ViewComponent::Base
  erb_template <<-ERB
    <details class="nhsuk-details<%= expander_class %>"<%= open_attr %>>
      <summary class="nhsuk-details__summary">
        <span class="nhsuk-details__summary-text">
          <%= summary %>
        </span>
      </summary>

      <div class="nhsuk-details__text">
        <%= content %>
      </div>
    </details>
  ERB

  renders_one :summary

  def initialize(summary: nil, open: false, expander: false)
    super

    with_summary { summary } if summary
    @open = open
    @expander = expander
  end

  def open_attr
    return unless @open

    " open"
  end

  def expander_class
    return unless @expander

    " nhsuk-expander"
  end
end
