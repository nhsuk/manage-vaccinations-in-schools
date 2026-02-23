# frozen_string_literal: true

class AppSchoolSummaryComponent < ViewComponent::Base
  def initialize(schoolable, change_links: {})
    @schoolable = schoolable
    @change_links = change_links
  end

  def call = helpers.govuk_summary_list(rows:)

  private

  attr_reader :schoolable, :change_links

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
        text: helpers.format_address_single_line(schoolable)
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
    row = { key: { text: "Name" }, value: { text: schoolable.name } }

    if (href = change_links[:name])
      row[:actions] = [{ text: "Change", href:, visually_hidden_text: "name" }]
    end

    row
  end

  def phase_row
    {
      key: {
        text: "Phase"
      },
      value: {
        text: schoolable.human_enum_name(:phase)
      }
    }
  end

  def programmes_row
    {
      key: {
        text: "Programmes"
      },
      value: {
        text: render(AppProgrammeTagsComponent.new(schoolable.programmes))
      }
    }
  end

  def urn_row
    row = {
      key: {
        text: "URN"
      },
      value: {
        text: tag.span(schoolable.urn_and_site, class: "app-u-code")
      }
    }

    if (href = change_links[:urn])
      row[:actions] = [{ text: "Change parent school", href: }]
    end

    row
  end

  def year_groups_row
    {
      key: {
        text: "Year groups"
      },
      value: {
        text: helpers.format_year_groups(schoolable.year_groups)
      }
    }
  end
end
