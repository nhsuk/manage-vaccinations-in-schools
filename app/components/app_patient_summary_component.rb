# frozen_string_literal: true

class AppPatientSummaryComponent < ViewComponent::Base
  def initialize(patient, change_links: {})
    super

    @patient = patient
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
      if @patient.has_preferred_name? || @patient.preferred_full_name_changed?
        summary_list.with_row do |row|
          row.with_key { "Known as" }
          row.with_value { format_preferred_full_name }
        end
      end
      summary_list.with_row do |row|
        row.with_key { "Date of birth" }
        row.with_value { format_date_of_birth }
      end
      if @patient.deceased?
        summary_list.with_row do |row|
          row.with_key { "Date of death" }
          row.with_value { format_date_of_death }
        end
      end
      summary_list.with_row do |row|
        row.with_key { "Gender" }
        row.with_value { format_gender_code }
      end
      unless @patient.restricted?
        summary_list.with_row do |row|
          row.with_key { "Address" }
          row.with_value { format_address }
        end
      end
      summary_list.with_row do |row|
        row.with_key { "School" }
        row.with_value { format_school }
      end
      summary_list.with_row do |row|
        row.with_key { "Year group" }
        row.with_value { format_year_group }
      end
      if (gp_practice = @patient.gp_practice)
        summary_list.with_row do |row|
          row.with_key { "GP surgery" }
          row.with_value { gp_practice.name }
        end
      end
    end
  end

  private

  def format_nhs_number
    highlight_if(
      helpers.patient_nhs_number(@patient),
      @patient.nhs_number_changed?
    )
  end

  def format_full_name
    highlight_if(
      @patient.full_name,
      @patient.given_name_changed? || @patient.family_name_changed?
    )
  end

  def format_preferred_full_name
    highlight_if(
      @patient.preferred_full_name,
      @patient.preferred_full_name_changed?
    )
  end

  def format_date_of_birth
    highlight_if(
      helpers.patient_date_of_birth(@patient),
      @patient.date_of_birth_changed?
    )
  end

  def format_date_of_death
    highlight_if(
      @patient.date_of_death.to_fs(:long),
      @patient.date_of_death_changed?
    )
  end

  def format_gender_code
    highlight_if(
      @patient.gender_code.to_s.humanize,
      @patient.gender_code_changed?
    )
  end

  def format_address
    highlight_if(
      helpers.format_address_multi_line(@patient),
      @patient.address_changed?
    )
  end

  def format_school
    highlight_if(
      helpers.patient_school(@patient),
      @patient.school_id_changed? || @patient.home_educated_changed?
    )
  end

  def format_year_group
    highlight_if(
      helpers.patient_year_group(@patient),
      @patient.year_group_changed? || @patient.registration_changed?
    )
  end

  def highlight_if(value, condition)
    condition ? tag.span(value, class: "app-highlight") : value
  end
end
