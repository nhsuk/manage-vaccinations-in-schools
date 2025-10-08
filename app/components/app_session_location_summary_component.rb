# frozen_string_literal: true

class AppSessionLocationSummaryComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= govuk_summary_list(rows:) %>
    
    <% if session.school? %>
      <%= govuk_button_link_to "Import class lists", import_session_path(session), secondary: true %>
    <% end %>
  ERB

  def initialize(session)
    @session = session
  end

  private

  attr_reader :session

  delegate :govuk_button_link_to,
           :govuk_link_to,
           :govuk_summary_list,
           :format_address_single_line,
           to: :helpers

  delegate :location, to: :session

  def rows
    [location_row, school_urn_row, consent_forms_row].compact
  end

  def location_row
    return unless location.has_address?

    text = [
      location.name,
      format_address_single_line(location)
    ].compact_blank.join(", ")

    generate_row("Location", text:)
  end

  def school_urn_row
    generate_row("School URN", text: location.urn_and_site)
  end

  def consent_forms_row
    links = [*online_consent_links, *download_consent_links]
    text =
      tag.ul(class: "nhsuk-list") do
        safe_join(links.map { |link| tag.li(link) })
      end

    generate_row("Consent forms", text:)
  end

  def online_consent_links
    return [] unless session.open_for_consent?

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
  end

  def download_consent_links
    session.programmes.map do |programme|
      link_to(
        "Download the #{programme.name} consent form (PDF)",
        consent_form_programme_path(programme)
      )
    end
  end

  def generate_row(key, text:, href: nil)
    return nil if text.blank?

    {
      key: {
        text: key
      },
      value: {
        text: (href ? helpers.link_to(text, href).html_safe : text)
      }
    }
  end
end
