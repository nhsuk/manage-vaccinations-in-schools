# frozen_string_literal: true

class AppChildSummaryComponent < ViewComponent::Base
  def initialize(child, show_parents: false, change_links: {})
    super

    @child = child
    @show_parents = show_parents
    @change_links = change_links
  end

  def call
    govuk_summary_list(actions: @change_links.present?) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "NHS number" }
        row.with_value { format_nhs_number }
        if (href = @change_links[:nhs_number])
          row.with_action(
            text: "Change",
            href:,
            visually_hidden_text: "NHS number"
          )
        end
      end
      summary_list.with_row do |row|
        row.with_key { "Full name" }
        row.with_value { format_full_name }
      end
      if @child.has_preferred_name? || @child.preferred_full_name_changed?
        summary_list.with_row do |row|
          row.with_key { "Known as" }
          row.with_value { format_preferred_full_name }
        end
      end
      summary_list.with_row do |row|
        row.with_key { "Date of birth" }
        row.with_value { format_date_of_birth }
      end
      if @child.try(:deceased?)
        summary_list.with_row do |row|
          row.with_key { "Date of death" }
          row.with_value { format_date_of_death }
        end
      end
      if @child.respond_to?(:gender_code)
        summary_list.with_row do |row|
          row.with_key { "Gender" }
          row.with_value { format_gender_code }
        end
      end
      unless @child.try(:restricted?)
        summary_list.with_row do |row|
          row.with_key { "Address" }
          row.with_value { format_address }
        end
      end
      summary_list.with_row do |row|
        row.with_key { "School" }
        row.with_value { format_school }
      end
      if @child.respond_to?(:year_group)
        summary_list.with_row do |row|
          row.with_key { "Year group" }
          row.with_value { format_year_group }
        end
      end
      if (gp_practice = @child.try(:gp_practice))
        summary_list.with_row do |row|
          row.with_key { "GP surgery" }
          row.with_value { gp_practice.name }
        end
      end
      if @show_parents && !@child.restricted?
        @child.parent_relationships.each do |parent_relationship|
          summary_list.with_row do |row|
            row.with_key { parent_relationship.ordinal_label.upcase_first }
            row.with_value do
              helpers.format_parent_with_relationship(parent_relationship)
            end
          end
        end
      end
    end
  end

  private

  def format_nhs_number
    highlight_if(helpers.patient_nhs_number(@child), @child.nhs_number_changed?)
  end

  def format_full_name
    highlight_if(
      @child.full_name,
      @child.given_name_changed? || @child.family_name_changed?
    )
  end

  def format_preferred_full_name
    highlight_if(
      @child.preferred_full_name,
      @child.preferred_full_name_changed?
    )
  end

  def format_date_of_birth
    highlight_if(
      helpers.patient_date_of_birth(@child),
      @child.date_of_birth_changed?
    )
  end

  def format_date_of_death
    highlight_if(
      @child.date_of_death.to_fs(:long),
      @child.date_of_death_changed?
    )
  end

  def format_gender_code
    highlight_if(@child.gender_code.to_s.humanize, @child.gender_code_changed?)
  end

  def format_address
    highlight_if(
      helpers.format_address_multi_line(@child),
      @child.address_changed?
    )
  end

  def format_school
    highlight_if(
      helpers.patient_school(@child),
      @child.school_id_changed? || @child.home_educated_changed?
    )
  end

  def format_year_group
    highlight_if(
      helpers.patient_year_group(@child),
      @child.year_group_changed? || @child.registration_changed?
    )
  end

  def highlight_if(value, condition)
    condition ? tag.span(value, class: "app-highlight") : value
  end
end
