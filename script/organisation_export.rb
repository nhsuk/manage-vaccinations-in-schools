# frozen_string_literal: true

require_relative "../config/environment"
require "caxlsx"

class OrganisationExport
  HEADERS = {
    patient: [
      "Patient ID",
      "First Name",
      "Last Name",
      "Date of Birth",
      "NHS Number",
      "School",
      "Year Group",
      "Gender"
    ],
    consent: [
      "Consent Status",
      "Consenter Name",
      "Consent Date",
      "Relationship to Patient"
    ],
    health_answers: ["Health Questions and Answers"],
    triage: ["Triage Status", "Triaged By", "Triage Date", "Notes"],
    gillick: ["Gillick Status", "Assessment Date", "Assessed By", "Notes"],
    vaccination: [
      "Vaccination Status",
      "Vaccination Date",
      "Administered By",
      "Batch Number",
      "Site",
      "Route",
      "Session Name"
    ]
  }.freeze

  def initialize(organisation_id)
    @organisation = Organisation.find(organisation_id)
    setup_headers
  end

  def generate
    package = Axlsx::Package.new
    workbook = package.workbook

    add_data_worksheet(workbook)

    org = @organisation.name.parameterize
    timestamp = Time.current.strftime("%Y%m%d")
    filename = "scratchpad/organisation-export-#{org}-#{timestamp}.xlsx"
    package.serialize(filename)

    puts "Excel file created successfully: #{filename}"
    filename
  end

  private

  def setup_headers
    @all_headers = HEADERS.values.flatten
  end

  def add_data_worksheet(workbook)
    workbook.add_worksheet(name: "Patient Data") do |sheet|
      sheet.add_row @all_headers

      patients.find_each do |patient|
        # Create a row for each consent, or one row if no consents
        consents = patient.consents.presence || [nil]
        consents.each { |consent| sheet.add_row build_row(patient, consent) }
      end
    end
  end

  def patients
    Patient
      .joins(school: { team: :organisation })
      .where(teams: { organisation_id: @organisation.id })
      .includes(
        :consents,
        :triages,
        :cohort,
        patient_sessions: %i[gillick_assessments vaccination_records],
        school: :team
      )
  end

  def build_row(patient, consent)
    [
      *patient_data(patient),
      *consent_data(consent),
      *health_answers_data(consent),
      *triage_data(patient.triages.last),
      *gillick_data(
        patient.patient_sessions.flat_map(&:gillick_assessments).last
      ),
      *vaccination_data(
        patient.patient_sessions.flat_map(&:vaccination_records).last
      )
    ]
  end

  def patient_data(patient)
    [
      patient.id,
      patient.given_name,
      patient.family_name,
      patient.date_of_birth&.to_fs(:govuk),
      patient.nhs_number,
      patient.school&.name,
      patient.cohort&.birth_academic_year,
      patient.gender_code
    ]
  end

  def consent_data(consent)
    return Array.new(HEADERS[:consent].length) if consent.nil?

    [
      consent.response,
      consent.parent&.full_name,
      consent.created_at&.to_fs(:govuk),
      consent
        .parent
        &.parent_relationships
        &.find_by(patient: consent.patient)
        &.type
    ]
  end

  def health_answers_data(consent)
    if consent&.health_answers.blank?
      return Array.new(HEADERS[:health_answers].length)
    end

    answers =
      consent.health_answers.map do |answer|
        next if answer.response.blank?
        notes = answer.notes.present? ? " - #{answer.notes}" : ""
        "#{answer.question}: #{answer.response}#{notes}"
      end

    [answers.compact.join("\n")]
  end

  def triage_data(triage)
    return Array.new(HEADERS[:triage].length) if triage.nil?

    [
      triage.status,
      triage.performed_by&.full_name,
      triage.created_at&.to_fs(:govuk),
      triage.notes
    ]
  end

  def gillick_data(gillick)
    return Array.new(HEADERS[:gillick].length) if gillick.nil?

    [
      gillick.gillick_competent ? "Competent" : "Not Competent",
      gillick.created_at&.to_fs(:govuk),
      gillick.assessor&.full_name,
      gillick.notes
    ]
  end

  def vaccination_data(vaccination)
    return Array.new(HEADERS[:vaccination].length) if vaccination.nil?

    [
      "Administered",
      vaccination.administered_at&.to_fs(:govuk),
      vaccination.performed_by&.full_name,
      vaccination.batch&.name,
      vaccination.delivery_site,
      vaccination.delivery_method,
      vaccination.patient_session&.session&.location&.name
    ]
  end
end

# Script execution
if ARGV.empty?
  puts "Usage: #{$PROGRAM_NAME} <organisation_id>"
  exit 1
end

begin
  OrganisationExport.new(ARGV[0]).generate
rescue ActiveRecord::RecordNotFound
  puts "Error: Organisation not found"
  exit 1
rescue StandardError => e
  puts "Error: #{e.message}"
  exit 1
end
