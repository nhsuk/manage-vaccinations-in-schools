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
    child_columns +
      [
        {
          name: "CHILD_POSTCODE",
          notes: "Optional, must be formatted as a valid postcode."
        }
      ] + parent_columns
  end

  def cohort_import_columns
    child_columns +
      [
        {
          name: "CHILD_POSTCODE",
          notes:
            "#{tag.strong("Required")}, must be formatted as a valid postcode."
        },
        {
          name: "CHILD_SCHOOL_URN",
          notes:
            "#{tag.strong("Required")}, must be 6 digits and numeric. " \
              "Use #{tag.i("888888")} for school unknown and #{tag.i("999999")} " \
              "for homeschooled."
        }
      ] + parent_columns
  end

  def immunisation_import_columns
    [
      {
        name: "ORGANISATION_CODE",
        notes:
          "#{tag.strong("Required")}, must be a valid " \
            "#{govuk_link_to("ODS code", "https://odsportal.digital.nhs.uk/")}"
      },
      {
        name: "SCHOOL_URN",
        notes:
          "#{tag.strong("Required")}, must be 6 digits and numeric. " \
            "Use #{tag.i("888888")} for school unknown and #{tag.i("999999")} " \
            "for homeschooled."
      },
      {
        name: "SCHOOL_NAME",
        notes: "Required if #{tag.i("SCHOOL_URN")} is #{tag.i("888888")}"
      },
      { name: "NHS_NUMBER", notes: "Optional, must be 10 digits and numeric" },
      { name: "PERSON_FORENAME", notes: tag.strong("Required") },
      { name: "PERSON_SURNAME", notes: tag.strong("Required") },
      {
        name: "PERSON_DOB",
        notes: "#{tag.strong("Required")}, must use either #{tag.i("YYYYMMDD")} or #{tag.i("DD/MM/YYYY")} format"
      },
      {
        name: "PERSON_GENDER_CODE",
        notes:
          "#{tag.strong("Required")}, must be #{tag.i("Not known")}, " \
            "#{tag.i("Male")}, #{tag.i("Female")}, #{tag.i("Not specified")}"
      },
      {
        name: "PERSON_POSTCODE",
        notes:
          "#{tag.strong("Required")}, must be formatted as a valid postcode"
      },
      {
        name: "DATE_OF_VACCINATION",
        notes: "#{tag.strong("Required")}, must use either #{tag.i("YYYYMMDD")} or #{tag.i("DD/MM/YYYY")} format"
      },
      {
        name: "TIME_OF_VACCINATION",
        notes: "Optional, must use #{tag.i("HH:MM:SS")} format"
      },
      {
        name: "VACCINE_GIVEN",
        notes:
          "Required if #{tag.code("VACCINATED")} is #{tag.i("Y")}, must be " +
            @programme
              .vaccines
              .pluck(:nivs_name)
              .map { tag.i(_1) }
              .to_sentence(
                last_word_connector: ", or ",
                two_words_connector: " or "
              )
      },
      {
        name: "BATCH_NUMBER",
        notes: "Required if #{tag.code("VACCINATED")} is #{tag.i("Y")}"
      },
      {
        name: "BATCH_EXPIRY_DATE",
        notes:
          "Required if #{tag.code("VACCINATED")} is #{tag.i("Y")}, must use either #{tag.i("YYYYMMDD")} or #{tag.i("DD/MM/YYYY")} format"
      },
      {
        name: "VACCINATED",
        notes:
          "Optional, must be #{tag.i("Y")} or #{tag.i("N")}. If omitted, " \
            "#{tag.i("Y")} is assumed."
      }
    ] + anatomical_site + reason_not_vaccinated_and_notes + dose_sequence +
      care_setting + performing_professional
  end

  def child_columns
    [
      { name: "CHILD_FIRST_NAME", notes: tag.strong("Required") },
      { name: "CHILD_LAST_NAME", notes: tag.strong("Required") },
      { name: "CHILD_PREFERRED_FIRST_NAME", notes: "Optional" },
      { name: "CHILD_PREFERRED_LAST_NAME", notes: "Optional" },
      {
        name: "CHILD_DATE_OF_BIRTH",
        notes:
          "#{tag.strong("Required")}, must use #{tag.i("DD/MM/YYYY")} or #{tag.i("YYYY-MM-DD")} format"
      },
      {
        name: "CHILD_YEAR_GROUP",
        notes:
          "Optional, numeric, the child’s year group, for example #{tag.i("8")}. If present, and " \
            "when the child’s date of birth would place them in a different year, this value can " \
            "be used to override the cohort the child will be placed in."
      },
      {
        name: "CHILD_REGISTRATION",
        notes:
          "Optional, the child’s registration group, for example #{tag.i("8T5")}"
      },
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
      { name: "CHILD_TOWN", notes: "Optional" }
    ]
  end

  def parent_columns
    %w[PARENT_1 PARENT_2].flat_map do |prefix|
      [
        { name: "#{prefix}_NAME", notes: "Optional" },
        {
          name: "#{prefix}_RELATIONSHIP",
          notes:
            "Optional, must be one of: #{tag.i("Mum")}, #{tag.i("Dad")} or " \
              "#{tag.i("Guardian")}"
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

  def reason_not_vaccinated_and_notes
    reasons = ImmunisationImportRow::REASONS.keys.sort.map { tag.i(_1) }
    reasons_sentence =
      reasons.to_sentence(
        last_word_connector: " or ",
        two_words_connector: " or "
      )

    [
      {
        name: "REASON_NOT_VACCINATED",
        notes:
          "Required if #{tag.code("VACCINATED")} is #{tag.i("N")}, must be #{reasons_sentence}"
      },
      { name: "NOTES", notes: "Optional" }
    ]
  end

  def anatomical_site
    sites = ImmunisationImportRow::DELIVERY_SITES.keys.sort.map { tag.i(_1) }

    site_sentence =
      sites.to_sentence(
        last_word_connector: " or ",
        two_words_connector: " or "
      )

    [
      {
        name: "ANATOMICAL_SITE",
        notes:
          "Required if #{tag.code("VACCINATED")} is #{tag.i("Y")}. It must be " \
            "appropriate for the vaccine delivery method and be one of: " \
            "#{site_sentence}"
      }
    ]
  end

  def dose_sequence
    return [] unless @programme.hpv?

    [
      {
        name: "DOSE_SEQUENCE",
        notes:
          "Required if #{tag.code("VACCINATED")} is #{tag.i("Y")}, " \
            "must be #{tag.i("1")}, #{tag.i("2")} or #{tag.i("3")}"
      }
    ]
  end

  def care_setting
    [
      {
        name: "CARE_SETTING",
        notes:
          "Required if #{tag.code("VACCINATED")} is #{tag.i("Y")}, must be " \
            "#{tag.i("1")} (school) or #{tag.i("2")} (clinic)"
      },
      {
        name: "CLINIC_NAME",
        notes:
          "Required if #{tag.code("CARE_SETTING")} is #{tag.i("2")}, must be " \
            "the name of a community clinic location"
      }
    ]
  end

  def performing_professional
    [
      { name: "PERFORMING_PROFESSIONAL_EMAIL", notes: tag.strong("Required") },
      {
        name: "PERFORMING_PROFESSIONAL_FORENAME",
        notes:
          "Required for uploading historical vaccination records unless " \
            "#{tag.code("PERFORMING_PROFESSIONAL_EMAIL")} is provided"
      },
      {
        name: "PERFORMING_PROFESSIONAL_SURNAME",
        notes:
          "Required for uploading historical vaccination records unless " \
            "#{tag.code("PERFORMING_PROFESSIONAL_EMAIL")} is provided"
      }
    ]
  end
end
