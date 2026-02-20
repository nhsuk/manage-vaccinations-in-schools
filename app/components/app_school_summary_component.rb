# frozen_string_literal: true

class AppSchoolSummaryComponent < ViewComponent::Base
  def initialize(school, change_links: {})
    @school = school
    @change_links = change_links
  end

  def call = helpers.govuk_summary_list(rows:)

  private

  attr_reader :school, :full_width, :change_links

  def rows
    [
      urn_row,
      name_row,
      address_row,
      phase_row,
      year_groups_row,
      programmes_row
    ].compact
  end

  def address_row
    row = {
      key: {
        text: "Address"
      },
      value: {
        text: helpers.format_address_single_line(school)
      }
    }
    if (href = change_links[:address])
      row[:actions] = [
        { text: "Change", href:, visually_hidden_text: "address" }
      ]
    end

    row
  end

  def name_row
    row = { key: { text: "Name" }, value: { text: school.name } }

    if (href = change_links[:name])
      row[:actions] = [{ text: "Change", href:, visually_hidden_text: "name" }]
    end

    row
  end

  def phase_row
    { key: { text: "Phase" }, value: { text: school.human_enum_name(:phase) } }
  end

  def programmes_row
    {
      key: {
        text: "Programmes"
      },
      value: {
        text: render(AppProgrammeTagsComponent.new(school.programmes))
      }
    }
  end

  def urn_row
    {
      key: {
        text: "URN"
      },
      value: {
        text: tag.span(school.urn_and_site, class: "app-u-code")
      }
    }
  end

  def year_groups_row
    {
      key: {
        text: "Year groups"
      },
      value: {
        text: helpers.format_year_groups(school.year_groups)
      }
    }
  end
end
