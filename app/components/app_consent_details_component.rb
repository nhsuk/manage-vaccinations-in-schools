class AppConsentDetailsComponent < ViewComponent::Base
  erb_template <<-ERB
      <%= govuk_summary_list classes: 'app-summary-list--no-bottom-border' do |summary_list|
        summary_list.with_row do |row|
          row.with_key { @consent.response_given? ?
                         "Given by" :
                         "Refused by" }
          row.with_value { @consent.who_responded.capitalize }
        end

        summary_list.with_row do |row|
          row.with_key { @consent.who_responded.capitalize }
          row.with_value do %>
            <%= @consent.parent_name %>
            <div class="nhsuk-u-margin-top-2 nhsuk-u-font-size-16">
              <% if @consent.parent_phone.present? %>
                Phone: <%= @consent.parent_phone %>
              <% end %>
              <% if @consent.parent_email.present? %>
                <br />
                Email: <%= @consent.parent_email %>
              <% end %>
            </div>
          <% end
        end

        summary_list.with_row do |row|
          row.with_key { 'Date' }
          row.with_value { @consent.created_at.to_fs(:nhsuk_date) }
        end

        summary_list.with_row do |row|
          row.with_key { 'Type of consent' }
          row.with_value { @consent.human_enum_name(:route) }
        end

        if @consent.response_refused?
          summary_list.with_row do |row|
            row.with_key { 'Reason for refusal' }
            row.with_value { @consent.human_enum_name(:reason_for_refusal) }
          end
        end
      end %>
  ERB

  def initialize(consent:)
    super

    @consent = consent
  end

  def summary
    response = @consent.response_given? ? "given" : "refused"
    by_whom = @consent.parent_name
    relationship = @consent
                     .human_enum_name(:parent_relationship)
                     .capitalize
    "Consent #{response} by #{by_whom} (#{relationship})"
  end
end
