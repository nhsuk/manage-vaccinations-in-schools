class AppConsentResponseComponent < ViewComponent::Base
  class AppSingleConsentResponseComponent < ViewComponent::Base
    erb_template <<-ERB
      <p class="nhsuk-body">
        <%= response %> (<%= route %>)
      </p>
      <p class="nhsuk-u-margin-bottom-2 nhsuk-u-secondary-text-color nhsuk-u-font-size-16 nhsuk-u-margin-bottom-0">
        <%= recorded_by_link %><br />
        <%= consent.recorded_at.to_fs(:nhsuk_date) %> at <%= consent.recorded_at.to_fs(:time) %>
      </p>
    ERB

    attr_reader :consent

    def initialize(consent:)
      super
      @consent = consent
    end

    def response
      if consent.respond_to?(:response_not_provided?) &&
           consent.response_not_provided?
        "No response when contacted"
      else
        consent.human_enum_name(:response).capitalize
      end
    end

    def route
      if consent.respond_to?(:route)
        consent.human_enum_name(:route).downcase
      else
        "online"
      end
    end

    def recorded_by_link
      if consent.respond_to?(:via_phone?) && consent.via_phone?
        link_to(
          consent.recorded_by.full_name,
          "mailto:#{consent.recorded_by.email}"
        )
      else
        link_to(consent.parent_name, "mailto:#{consent.parent_email}")
      end
    end
  end

  erb_template <<-ERB
    <% if @consents.size == 1 %>
      <%= render(AppSingleConsentResponseComponent.new(consent: @consents.first)) %>
    <% elsif @consents.size > 1 %>
      <ul class="nhsuk-list nhsuk-list--bullet app-list--events">
        <% @consents.each do |consent| %>
          <li>
            <%= render(AppSingleConsentResponseComponent.new(consent: consent)) %>
          </li>
        <% end %>
      </ul>
    <% end %>
  ERB

  def initialize(consents:)
    super
    @consents = consents
  end
end
