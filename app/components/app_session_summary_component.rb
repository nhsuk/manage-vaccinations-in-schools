# frozen_string_literal: true

class AppSessionSummaryComponent < ViewComponent::Base
  def initialize(session)
    super

    @session = session
  end

  def call
    govuk_summary_list(
      classes: %w[nhsuk-summary-list--no-border app-summary-list--full-width]
    ) do |summary_list|
      if (urn = location.urn).present?
        summary_list.with_row do |row|
          row.with_key { "School URN" }
          row.with_value { urn }
        end
      end

      if location.has_address?
        summary_list.with_row do |row|
          row.with_key { "Address" }
          row.with_value { helpers.format_address_multi_line(location) }
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Consent forms" }
        row.with_value { consent_form_links }
      end
    end
  end

  private

  attr_reader :session

  delegate :location, to: :session

  def consent_form_links
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

    tag.ul(class: "nhsuk-list") { safe_join(links.map { tag.li(it) }) }
  end
end
