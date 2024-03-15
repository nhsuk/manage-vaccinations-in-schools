class AppConsentResponseComponent < ViewComponent::Base
  class AppSingleConsentResponseComponent < ViewComponent::Base
    erb_template <<-ERB
      <p class="nhsuk-body">
        <%= @response %> (<%= @route %>)
      </p>
      <p class="nhsuk-u-margin-bottom-2 nhsuk-u-secondary-text-color nhsuk-u-font-size-16 nhsuk-u-margin-bottom-0">
        <% if @recorded_by.present? %>
          <%= mail_to(@recorded_by.email, @recorded_by.full_name) %>,
        <% end %>
        <%= @timestamp.to_fs(:app_date_time) %>
      </p>
    ERB

    def initialize(response:, route:, timestamp:, recorded_by: nil)
      super
      @response = response
      @route = route
      @timestamp = timestamp
      @recorded_by = recorded_by
    end
  end

  erb_template <<-ERB
    <% if @consents.size == 1 %>
      <% consent = @consents.first %>
      <%= render AppSingleConsentResponseComponent.new(
            response: response_text(consent),
            route: consent.human_enum_name(:route).downcase,
            timestamp: consent.recorded_at,
            recorded_by: consent.recorded_by
          ) %>
    <% elsif @consents.size > 1 %>
      <ul class="nhsuk-list nhsuk-list--bullet app-list--events">
        <% @consents.each do |consent| %>
          <li>
            <%= render AppSingleConsentResponseComponent.new(
                  response: response_text(consent),
                  route: consent.human_enum_name(:route).downcase,
                  timestamp: consent.recorded_at,
                  recorded_by: consent.recorded_by
                ) %>
          </li>
        <% end %>
      </ul>
    <% end %>
  ERB

  def initialize(consents:)
    super
    @consents = consents
  end

  def response_text(consent)
    if consent.response_not_provided?
      "No response when contacted"
    else
      consent.human_enum_name(:response).capitalize
    end
  end
end
