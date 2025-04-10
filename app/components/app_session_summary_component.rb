# frozen_string_literal: true

class AppSessionSummaryComponent < ViewComponent::Base
  erb_template <<-ERB
    <h3 class="nhsuk-heading-s nhsuk-u-margin-top-5">
      <%= @session.location.name %>
    </h3>

     <%= govuk_summary_list(rows:, classes:) %>
  ERB

  def initialize(session)
    super

    @session = session
  end

  private

  attr_reader :session

  delegate :location, to: :session

  def classes
    %w[nhsuk-summary-list--no-border app-summary-list--full-width]
  end

  def rows
    [school_urn_row, address_row, consent_forms_row].compact
  end

  def school_urn_row
    if (text = location.urn).present?
      { key: { text: "School URN" }, value: { text: } }
    end
  end

  def address_row
    if location.has_address?
      {
        key: {
          text: "Address"
        },
        value: {
          text: helpers.format_address_multi_line(location)
        }
      }
    end
  end

  def consent_forms_row
    online_consent_links =
      if session.open_for_consent?
        ProgrammeGrouper
          .call(session.programmes)
          .map do |_group, programmes|
            govuk_link_to(
              "View the #{programmes.map(&:name).to_sentence} online consent form",
              start_parent_interface_consent_forms_path(
                session,
                programmes.map(&:to_param).join("-")
              ),
              new_tab: true
            )
          end
      else
        []
      end

    download_consent_links =
      session.programmes.map do
        link_to(
          "Download the #{it.name} consent form (PDF)",
          consent_form_programme_path(it)
        )
      end

    links = online_consent_links + download_consent_links

    {
      key: {
        text: "Consent forms"
      },
      value: {
        text:
          tag.ul(class: "nhsuk-list") { safe_join(links.map { tag.li(it) }) }
      }
    }
  end
end
