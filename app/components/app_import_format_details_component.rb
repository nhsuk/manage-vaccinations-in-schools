# frozen_string_literal: true

class AppImportFormatDetailsComponent < ViewComponent::Base
  def initialize(import:)
    @import = import
  end

  private

  delegate :team, to: :@import
  delegate :govuk_details, :govuk_table, to: :helpers

  def summary_text
    case @import
    when ClassImport
      "How to format your Mavis CSV file for class lists"
    when CohortImport
      "How to format your Mavis CSV file for child records"
    when ImmunisationImport
      if team.has_upload_only_access?
        "How to format your CSV file for vaccination records"
      else
        "How to format your Mavis CSV file for vaccination records"
      end
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
    if team.has_upload_only_access?
      bulk_immunisation_import_columns
    else
      poc_immunisation_import_columns
    end
  end

  def poc_immunisation_import_columns
    organisation_code(optionality: "Optional") +
      school_urn(optionality: "Optional") + school_name +
      nhs_number(optionality: "Optional") +
      patient_demographics(optionality: "Required") +
      date_and_time_of_vaccination(date_optionality: "Required") +
      vaccinated(
        optionality: "Required",
        extra_notes:
          "Can be omitted if #{tag.code("VACCINE_GIVEN")} is provided."
      ) + vaccine_and_batch + programme + anatomical_site +
      reason_not_vaccinated_and_notes + dose_sequence + care_setting +
      performing_professional
  end

  def bulk_immunisation_import_columns
    organisation_code(optionality: "Mandatory") +
      school_urn(optionality: "Mandatory") +
      nhs_number(optionality: "Required") +
      patient_demographics(
        optionality: "Mandatory",
        gender_field_name: "PERSON_GENDER"
      ) +
      vaccinated(
        optionality: "Optional",
        extra_notes:
          "Rows with the value #{tag.i("N")} will not be validated and will not be imported."
      ) + date_and_time_of_vaccination(date_optionality: "Mandatory") +
      bulk_vaccine_and_batch + bulk_anatomical_site + bulk_dose_sequence +
      bulk_performing_professional_names + local_patient_id
  end

  def child_columns
    [
      {
        name: "CHILD_FIRST_NAME",
        notes:
          "#{tag.strong("Required")}, must use alphabetical characters (you" \
            " can include accents like Chloë, hyphens like Anne-Marie or" \
            " apostrophes like D'Arcy but no other special characters)."
      },
      {
        name: "CHILD_LAST_NAME",
        notes:
          "#{tag.strong("Required")}, must use alphabetical characters (you" \
            " can include accents like Jiménez, hyphens like Burne-Jones or" \
            " apostrophes like O'Hare but no other special characters)."
      },
      {
        name: "CHILD_PREFERRED_FIRST_NAME",
        notes:
          "Optional, must use alphabetical characters (you can include" \
            " accents like Chloë, hyphens like Anne-Marie or apostrophes like" \
            " D'Arcy but no other special characters)."
      },
      {
        name: "CHILD_PREFERRED_LAST_NAME",
        notes:
          "Optional, must use alphabetical characters (you can include" \
            " accents like Jiménez, hyphens like Burne-Jones or apostrophes" \
            " like O'Hare but no other special characters)."
      },
      {
        name: "CHILD_DATE_OF_BIRTH",
        notes:
          "#{tag.strong("Required")}, must use #{tag.i("DD/MM/YYYY")} or #{tag.i("YYYY-MM-DD")} format."
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
          "Optional, the child’s registration group, for example #{tag.i("8T5")}."
      },
      {
        name: "CHILD_NHS_NUMBER",
        notes: "Optional, must be 10 digits and numeric."
      },
      {
        name: "CHILD_GENDER",
        notes:
          "Optional, must be one of: #{tag.i("Male")}, #{tag.i("Female")}, " \
            "#{tag.i("Not known")} or #{tag.i("Not specified")}."
      },
      { name: "CHILD_ADDRESS_LINE_1", notes: "Optional" },
      { name: "CHILD_ADDRESS_LINE_2", notes: "Optional" },
      { name: "CHILD_TOWN", notes: "Optional" }
    ]
  end

  def organisation_code(optionality:)
    [
      {
        name: "ORGANISATION_CODE",
        notes:
          "#{tag.strong(optionality)}, must be a valid #{link_to("ODS code", "https://odsportal.digital.nhs.uk/")}."
      }
    ]
  end

  def nhs_number(optionality:)
    [
      {
        name: "NHS_NUMBER",
        notes:
          "#{tag.strong(optionality)}, must be a valid #{link_to("NHS number", "https://www.datadictionary.nhs.uk/attributes/nhs_number.html")}."
      }
    ]
  end

  def school_urn(optionality:)
    [
      {
        name: "SCHOOL_URN",
        notes:
          "#{tag.strong(optionality)}, must be 6 digits and numeric. " \
            "Use #{tag.i("888888")} for school unknown and #{tag.i("999999")} " \
            "for homeschooled."
      }
    ]
  end

  def school_name
    [
      {
        name: "SCHOOL_NAME",
        notes: "Required if #{tag.code("SCHOOL_URN")} is #{tag.i("888888")}."
      }
    ]
  end

  def patient_demographics(
    optionality:,
    gender_field_name: "PERSON_GENDER_CODE"
  )
    [
      { name: "PERSON_FORENAME", notes: tag.strong(optionality) },
      { name: "PERSON_SURNAME", notes: tag.strong(optionality) },
      {
        name: "PERSON_DOB",
        notes:
          "#{tag.strong(optionality)}, must use either #{tag.i("YYYYMMDD")} or " \
            "#{tag.i("DD/MM/YYYY")} format."
      },
      {
        name: gender_field_name,
        notes:
          "#{tag.strong(optionality)}, must be #{tag.i("Not known")}, " \
            "#{tag.i("Male")}, #{tag.i("Female")}, #{tag.i("Not specified")}."
      },
      {
        name: "PERSON_POSTCODE",
        notes:
          "#{tag.strong(optionality)}, must be formatted as a valid postcode."
      }
    ]
  end

  def vaccinated(optionality:, extra_notes: "")
    optionality_html =
      if %w[Mandatory Required].include?(optionality)
        tag.strong(optionality)
      else
        optionality
      end

    [
      {
        name: "VACCINATED",
        notes:
          "#{optionality_html}, must be #{tag.i("Y")} or #{tag.i("N")}. #{extra_notes}"
      }
    ]
  end

  def date_and_time_of_vaccination(date_optionality:)
    [
      {
        name: "DATE_OF_VACCINATION",
        notes:
          "#{tag.strong(date_optionality)}, must use either #{tag.i("YYYYMMDD")} or #{tag.i("DD/MM/YYYY")} format."
      },
      {
        name: "TIME_OF_VACCINATION",
        notes: "Optional, must use #{tag.i("HH:MM:SS")} format."
      }
    ]
  end

  def parent_columns
    %w[PARENT_1 PARENT_2].flat_map do |prefix|
      [
        {
          name: "#{prefix}_NAME",
          notes:
            "Optional, must use alphabetical characters (you can include" \
              " accents like Chloë, hyphens like Anne-Marie or apostrophes" \
              " like D'Arcy but no other special characters)."
        },
        {
          name: "#{prefix}_RELATIONSHIP",
          notes:
            "Optional, must be one of: #{tag.i("Mum")}, #{tag.i("Dad")} or " \
              "#{tag.i("Guardian")}."
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

  def programme
    programmes = team.programmes.flat_map(&:import_names).map { tag.i(it) }

    programmes_sentence =
      programmes.to_sentence(
        last_word_connector: ", or ",
        two_words_connector: " or "
      )

    [
      {
        name: "PROGRAMME",
        notes: "#{tag.strong("Required")}, must be #{programmes_sentence}."
      }
    ]
  end

  def make_vaccines_sentence(vaccines:)
    vaccines.to_sentence(
      last_word_connector: ", or ",
      two_words_connector: " or "
    )
  end

  def vaccine_and_batch
    vaccines = team.vaccines.pluck(:upload_name).map { tag.i(it) }
    vaccines_sentence = make_vaccines_sentence(vaccines:)

    [
      {
        name: "VACCINE_GIVEN",
        notes: "Optional, must be one of: #{vaccines_sentence}."
      },
      {
        name: "BATCH_NUMBER",
        notes: "Required if #{tag.code("BATCH_EXPIRY_DATE")} is provided."
      },
      {
        name: "BATCH_EXPIRY_DATE",
        notes:
          "Required if #{tag.code("BATCH_NUMBER")} is provided, must use " \
            "either #{tag.i("YYYYMMDD")} or #{tag.i("DD/MM/YYYY")} format."
      }
    ]
  end

  def bulk_vaccine_and_batch
    hpv_vaccines =
      Programme.hpv.vaccines.pluck(:nivs_name).compact.map { tag.i(it) }
    flu_vaccines =
      Programme.flu.vaccines.pluck(:nivs_name).compact.map { tag.i(it) }

    hpv_vaccines_sentence = make_vaccines_sentence(vaccines: hpv_vaccines)
    flu_vaccines_sentence = make_vaccines_sentence(vaccines: flu_vaccines)

    [
      {
        name: "VACCINE_GIVEN",
        notes:
          "#{tag.strong("Mandatory")}" \
            "#{tag.br}#{tag.br}" \
            "For HPV records, must be one of: #{hpv_vaccines_sentence}." \
            "#{tag.br}#{tag.br}" \
            "For flu records, must be one of: #{flu_vaccines_sentence}."
      },
      { name: "BATCH_NUMBER", notes: tag.strong("Mandatory") },
      {
        name: "BATCH_EXPIRY_DATE",
        notes:
          "#{tag.strong("Mandatory")}, must use #{tag.i("YYYYMMDD")} format."
      }
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
          "Optional, if provided must be appropriate for the vaccine delivery method " \
            "and be one of: #{site_sentence}."
      }
    ]
  end

  def reason_not_vaccinated_and_notes
    reasons =
      ImmunisationImportRow::REASONS_NOT_ADMINISTERED.keys.sort.map do
        tag.i(_1)
      end
    reasons_sentence =
      reasons.to_sentence(
        last_word_connector: " or ",
        two_words_connector: " or "
      )

    [
      {
        name: "REASON_NOT_VACCINATED",
        notes:
          "Required if #{tag.code("VACCINATED")} is #{tag.i("N")}, must be #{reasons_sentence}."
      },
      { name: "NOTES", notes: "Optional" }
    ]
  end

  def dose_sequence
    special_values =
      ImmunisationImportRow::DOSE_SEQUENCES
        .values
        .flat_map(&:keys)
        .sort
        .uniq
        .map { tag.i(it) }

    special_values_sentence =
      special_values.to_sentence(
        last_word_connector: " or ",
        two_words_connector: " or "
      )

    [
      {
        name: "DOSE_SEQUENCE",
        notes: "Optional, must be a number or #{special_values_sentence}."
      }
    ]
  end

  def care_setting
    [
      {
        name: "CARE_SETTING",
        notes:
          "Optional, must be #{tag.i("1")} (school) or #{tag.i("2")} (clinic)."
      },
      {
        name: "CLINIC_NAME",
        notes:
          "Required if #{tag.code("CARE_SETTING")} is #{tag.i("2")}, must be " \
            "the name of a community clinic location."
      }
    ]
  end

  def performing_professional
    [
      {
        name: "PERFORMING_PROFESSIONAL_EMAIL",
        notes: "Required if uploading offline vaccination records."
      },
      { name: "PERFORMING_PROFESSIONAL_FORENAME", notes: "Optional" },
      { name: "PERFORMING_PROFESSIONAL_SURNAME", notes: "Optional" }
    ]
  end

  def bulk_performing_professional_names
    [
      {
        name: "PERFORMING_PROFESSIONAL_FORENAME",
        notes: "Mandatory for flu records, optional for HPV records."
      },
      {
        name: "PERFORMING_PROFESSIONAL_SURNAME",
        notes: "Mandatory for flu records, optional for HPV records."
      }
    ]
  end

  def supplier
    [
      {
        name: "SUPPLIER_EMAIL",
        notes: "Required if uploading delegated vaccination records."
      }
    ]
  end

  def bulk_anatomical_site
    sites = ImmunisationImportRow::DELIVERY_SITES.keys.sort.map { tag.i(_1) }

    site_sentence =
      sites.to_sentence(
        last_word_connector: " or ",
        two_words_connector: " or "
      )

    [
      {
        name: "ANATOMICAL_SITE",
        notes: "#{tag.strong("Mandatory")}, must be one of: #{site_sentence}."
      }
    ]
  end

  def bulk_dose_sequence
    hpv_max = Programme.hpv.maximum_dose_sequence
    flu_max = Programme.flu.maximum_dose_sequence

    [
      {
        name: "DOSE_SEQUENCE",
        notes:
          "Mandatory for HPV records, optional for flu records." \
            "#{tag.br} #{tag.br}" \
            "Must be a number between 1 and #{hpv_max} for HPV records and between 1 and #{flu_max} for flu records."
      }
    ]
  end

  def local_patient_id
    [
      { name: "LOCAL_PATIENT_ID", notes: tag.strong("Mandatory") },
      { name: "LOCAL_PATIENT_ID_URI", notes: tag.strong("Mandatory") }
    ]
  end
end
