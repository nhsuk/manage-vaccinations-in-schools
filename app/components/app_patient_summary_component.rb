# frozen_string_literal: true

class AppPatientSummaryComponent < ViewComponent::Base
  def initialize(patient:)
    super

    @patient = patient
  end

  def call
    govuk_summary_list do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "NHS number" }
        row.with_value { format_nhs_number }
      end
      summary_list.with_row do |row|
        row.with_key { "Full name" }
        row.with_value { format_full_name }
      end
      summary_list.with_row do |row|
        row.with_key { "Date of birth" }
        row.with_value { format_date_of_birth }
      end
      summary_list.with_row do |row|
        row.with_key { "Sex" }
        row.with_value { format_gender_code }
      end
      summary_list.with_row do |row|
        row.with_key { "Postcode" }
        row.with_value { format_postcode }
      end
      summary_list.with_row do |row|
        row.with_key { "School" }
        row.with_value { format_school }
      end
    end
  end

  private

  def format_nhs_number
    highlight_if(
      helpers.format_nhs_number(@patient.nhs_number),
      @patient.nhs_number_changed?
    )
  end

  def format_full_name
    highlight_if(
      @patient.full_name,
      @patient.first_name_changed? || @patient.last_name_changed?
    )
  end

  def format_date_of_birth
    highlight_if(
      @patient.date_of_birth.to_date.to_fs(:long),
      @patient.date_of_birth_changed?
    )
  end

  def format_gender_code
    highlight_if(
      @patient.gender_code.to_s.humanize,
      @patient.gender_code_changed?
    )
  end

  def format_postcode
    highlight_if(@patient.address_postcode, @patient.address_postcode_changed?)
  end

  def format_school
    highlight_if(@patient.school&.name, @patient.school_id_changed?)
  end

  def highlight_if(value, condition)
    condition ? tag.span(value, class: "app-highlight") : value
  end
end
