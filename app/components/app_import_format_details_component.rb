# frozen_string_literal: true

class AppImportFormatDetailsComponent < ViewComponent::Base
  def initialize(import:, programme: nil)
    super

    @import = import
    @programme = programme
  end

  private

  def summary_text
    case @import
    when ClassImport
      "How to format your CSV for class lists"
    when CohortImport
      "How to format your CSV for child records"
    when ImmunisationImport
      "How to format your CSV for vaccination records"
    else
      raise ArgumentError, "Unsupported import type: #{@import.class}"
    end
  end

  def columns
    case @import
    when ClassImport
      class_import_columns
    when CohortImport
      cohort_import_columns
    when ImmunisationImport
      immunisation_import_columns
    end
  end

  def class_import_columns
    [
      { name: "CHILD_FIRST_NAME", notes: tag.strong("Required") },
      { name: "CHILD_LAST_NAME", notes: tag.strong("Required") },
      { name: "CHILD_DATE_OF_BIRTH", notes: tag.strong("Required") },
      {
        name: "CHILD_NHS_NUMBER",
        notes: "Optional, must be 10 digits and numeric"
      },
      {
        name: "CHILD_GENDER",
        notes:
          "Optional, must be one of: #{tag.i("Male")}, #{tag.i("Female")}, " \
            "#{tag.i("Not known")} or #{tag.i("Not specified")}"
      },
      { name: "CHILD_ADDRESS_LINE_1", notes: "Optional" },
      { name: "CHILD_ADDRESS_LINE_2", notes: "Optional" },
      { name: "CHILD_TOWN", notes: "Optional" },
      {
        name: "CHILD_POSTCODE",
        notes:
          "#{tag.strong("Required")}, must be formatted as a valid postcode.".html_safe
      }
    ] + parent_columns
  end

  def cohort_import_columns
    [
      { name: "CHILD_FIRST_NAME", notes: tag.strong("Required") },
      { name: "CHILD_LAST_NAME", notes: tag.strong("Required") },
      { name: "CHILD_DATE_OF_BIRTH", notes: tag.strong("Required") },
      {
        name: "CHILD_SCHOOL_URN",
        notes:
          "#{tag.strong("Required")}, must be 6 digits and numeric. " \
            "Use #{tag.i("888888")} for school unknown and #{tag.i("999999")} " \
            "for homeschooled."
      },
      {
        name: "CHILD_NHS_NUMBER",
        notes: "Optional, must be 10 digits and numeric"
      },
      {
        name: "CHILD_GENDER",
        notes:
          "Optional, must be one of: #{tag.i("Male")}, #{tag.i("Female")}, " \
            "#{tag.i("Not known")} or #{tag.i("Not specified")}".html_safe
      },
      { name: "CHILD_ADDRESS_LINE_1", notes: "Optional" },
      { name: "CHILD_ADDRESS_LINE_2", notes: "Optional" },
      { name: "CHILD_TOWN", notes: "Optional" },
      {
        name: "CHILD_POSTCODE",
        notes:
          "#{tag.strong("Required")}, must be formatted as a valid postcode."
      }
    ] + parent_columns
  end

  def immunisation_import_columns
    [
      {
        name: "ORGANISATION_CODE",
        notes:
          "#{tag.strong("Required")}, must be a valid " \
            "#{govuk_link_to("ODS code", "https://odsportal.digital.nhs.uk/")}".html_safe
      },
      {
        name: "SCHOOL_URN",
        notes:
          "#{tag.strong("Required")}, must be 6 digits and numeric. " \
            "Use #{tag.i("888888")} for school unknown and #{tag.i("999999")} " \
            "for homeschooled.".html_safe
      },
      {
        name: "SCHOOL_NAME",
        notes:
          "Required if #{tag.i("SCHOOL_URN")} is #{tag.i("888888")}".html_safe
      },
      { name: "NHS_NUMBER", notes: "Optional, must be 10 digits and numeric" },
      { name: "PERSON_FORENAME", notes: tag.strong("Required") },
      { name: "PERSON_SURNAME", notes: tag.strong("Required") },
      { name: "PERSON_DOB", notes: tag.strong("Required") },
      {
        name: "PERSON_GENDER_CODE",
        notes:
          "#{tag.strong("Required")}, must be #{tag.i("Not known")}, " \
            "#{tag.i("Male")}, #{tag.i("Female")}, #{tag.i("Not specified")}".html_safe
      },
      {
        name: "PERSON_POSTCODE",
        notes:
          "#{tag.strong("Required")}, must be formatted as a valid postcode".html_safe
      },
      {
        name: "DATE_OF_VACCINATION",
        notes:
          "#{tag.strong("Required")}, must use #{tag.i("YYYYMMDD")} format".html_safe
      },
      {
        name: "VACCINE_GIVEN",
        notes:
          "#{tag.strong("Required")}, must be ".html_safe +
            @programme
              .vaccines
              .pluck(:nivs_name)
              .map { tag.i(_1) }
              .to_sentence(
                last_word_connector: ", or ",
                two_words_connector: " or "
              )
              .html_safe
      },
      { name: "BATCH_NUMBER", notes: tag.strong("Required") },
      {
        name: "BATCH_EXPIRY_DATE",
        notes:
          "#{tag.strong("Required")}, must use #{tag.i("YYYYMMDD")} format".html_safe
      },
      {
        name: "ANATOMICAL_SITE",
        notes:
          "#{tag.strong("Required")}, must be #{tag.i("Left Buttock")}, " \
            "#{tag.i("Right Buttock")}, #{tag.i("Left Thigh")}, " \
            "#{tag.i("Right Thigh")}, #{tag.i("Left Upper Arm")}, " \
            "#{tag.i("Right Upper Arm")} or #{tag.i("Nasal")}".html_safe
      }
    ] + dose_sequence + vaccinated + care_setting + performing_professional
  end

  def parent_columns
    %w[PARENT_1 PARENT_2].flat_map do |prefix|
      [
        { name: "#{prefix}_NAME", notes: "Optional" },
        {
          name: "#{prefix}_RELATIONSHIP",
          notes:
            "Optional, must be one of: #{tag.i("Mum")}, #{tag.i("Dad")} or " \
              "#{tag.i("Guardian")}".html_safe
        },
        {
          name: "#{prefix}_EMAIL",
          notes: "Optional, must be formatted as a valid email address."
        },
        {
          name: "#{prefix}_PHONE",
          notes: "Optional, must be formatted as a valid phone number."
        }
      ]
    end
  end

  def dose_sequence
    return [] unless @programme.hpv?

    [
      {
        name: "DOSE_SEQUENCE",
        notes:
          "#{tag.strong("Required")}, must be #{tag.i("1")}, #{tag.i("2")} or " \
            "#{tag.i("3")}".html_safe
      }
    ]
  end

  def care_setting
    return [] unless @programme.hpv?
    [
      {
        name: "CARE_SETTING",
        notes:
          "Required if #{tag.code("VACCINATED")} is #{tag.i("Y")}. Must be " \
            "#{tag.i("1")} (school) or #{tag.i("2")} (care setting)".html_safe
      }
    ]
  end

  def vaccinated
    [
      {
        name: "VACCINATED",
        notes:
          "Optional, must be #{tag.i("Y")} or #{tag.i("N")}. If omitted, " \
            "#{tag.i("Y")} is assumed.".html_safe
      }
    ]
  end

  def performing_professional
    [
      {
        name: "PERFORMING_PROFESSIONAL_FORENAME",
        notes:
          "Required if #{tag.code("VACCINATED")} is #{tag.i("Y")}".html_safe
      },
      {
        name: "PERFORMING_PROFESSIONAL_SURNAME",
        notes:
          "Required if #{tag.code("VACCINATED")} is #{tag.i("Y")}".html_safe
      }
    ]
  end
end
