# frozen_string_literal: true

class AppImportPDSUnmatchedSummaryComponent < ViewComponent::Base
  def initialize(changesets:)
    @changesets = changesets.sort_by(&:row_number)
  end

  def call
    helpers.govuk_table(
      html_attributes: {
        class: "nhsuk-table-responsive"
      }
    ) do |table|
      table.with_head do |head|
        head.with_row do |row|
          row.with_cell(text: "First name")
          row.with_cell(text: "Last name")
          row.with_cell(text: "Date of birth")
          row.with_cell(text: "Postcode")
        end
      end

      table.with_body do |body|
        @changesets.each do |changeset|
          body.with_row do |row|
            row.with_cell do
              content_tag(
                :span,
                "First name",
                class: "nhsuk-table-responsive__heading"
              ) + changeset.child_attributes["given_name"]&.to_s
            end

            row.with_cell do
              content_tag(
                :span,
                "Last name",
                class: "nhsuk-table-responsive__heading"
              ) + changeset.child_attributes["family_name"]&.to_s
            end

            row.with_cell do
              content_tag(
                :span,
                "Date of birth",
                class: "nhsuk-table-responsive__heading"
              ) +
                changeset.child_attributes["date_of_birth"]&.to_date&.to_fs(
                  :long
                )
            end

            row.with_cell do
              content_tag(
                :span,
                "Postcode",
                class: "nhsuk-table-responsive__heading"
              ) + changeset.child_attributes["address_postcode"]&.to_s
            end
          end
        end
      end
    end
  end
end
