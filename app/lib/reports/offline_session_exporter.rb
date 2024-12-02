# frozen_string_literal: true

class Reports::OfflineSessionExporter
  include Reports::ExportFormatters

  def initialize(session)
    @session = session
  end

  def call
    Axlsx::Package
      .new { |package| add_vaccinations_sheet(package) }
      .to_stream
      .read
  end

  def self.call(*args, **kwargs)
    new(*args, **kwargs).call
  end

  private_class_method :new

  private

  attr_reader :session

  delegate :location, :organisation, to: :session

  def add_vaccinations_sheet(package)
    package.use_shared_strings = true

    workbook = package.workbook

    cached_styles = CachedStyles.new(workbook)

    workbook.add_worksheet(name: "Vaccinations") do |sheet|
      sheet.add_row(columns.map { _1.to_s.upcase })

      patient_sessions.each do |patient_session|
        rows(patient_session:).each { |row| row.add_to(sheet:, cached_styles:) }
      end

      sheet.sheet_view.pane do |pane|
        pane.top_left_cell = "C2"
        pane.state = :frozen_split
        pane.y_split = 1
        pane.x_split = 2
        pane.active_pane = :bottom_right
      end
    end
  end

  def columns
    @columns ||=
      %i[
        person_forename
        person_surname
        organisation_code
        school_urn
        school_name
        care_setting
        person_dob
        year_group
        person_gender_code
        person_address_line_1
        person_postcode
        nhs_number
        consent_status
        consent_details
        health_question_answers
        triage_status
        triaged_by
        triage_date
        triage_notes
        gillick_status
        gillick_assessment_date
        gillick_assessed_by
        gillick_assessment_notes
        vaccinated
        date_of_vaccination
        time_of_vaccination
        programme_name
        vaccine_given
        performing_professional_email
        batch_number
        batch_expiry_date
        anatomical_site
        dose_sequence
        reason_not_vaccinated
        notes
        uuid
      ].tap do |values|
        values.insert(6, :clinic_name) if location.generic_clinic?
      end
  end

  def patient_sessions
    session
      .patient_sessions
      .includes(
        patient: %i[cohort school],
        consents: [:patient, { parent: :parent_relationships }],
        gillick_assessments: :performed_by,
        triages: :performed_by,
        vaccination_records: %i[batch performed_by_user vaccine]
      )
      .strict_loading
  end

  def rows(patient_session:)
    vaccination_records =
      patient_session.vaccination_records.order(:performed_at)

    row_style = {
      strike: patient_session.patient.invalidated?,
      bg_color: patient_session.consent_given? ? nil : "F7D4D1",
      border: {
        style: :thin,
        color: "000000"
      }
    }

    if vaccination_records.any?
      vaccination_records.map do |vaccination_record|
        Row.new(columns, style: row_style) do |row|
          add_patient_cells(row, patient_session:)
          add_existing_row_cells(row, vaccination_record:)
        end
      end
    elsif patient_session.consent_refused?
      []
    else
      session.programmes.map do |programme|
        Row.new(columns, style: row_style) do |row|
          add_patient_cells(row, patient_session:)
          add_new_row_cells(row, programme:)
        end
      end
    end
  end

  def add_patient_cells(row, patient_session:)
    consents = patient_session.latest_consents
    gillick_assessment = patient_session.latest_gillick_assessment
    patient = patient_session.patient
    triage = patient_session.latest_triage

    row[:organisation_code] = organisation.ods_code
    row[:school_urn] = school_urn(location:, patient:)
    row[:school_name] = school_name(location:, patient:)
    row[:care_setting] = Cell.new(care_setting(location:), type: :integer)
    row[:person_forename] = patient.given_name
    row[:person_surname] = patient.family_name
    row[:person_dob] = patient.date_of_birth
    row[:year_group] = patient.year_group
    row[:person_gender_code] = patient.gender_code.humanize
    row[:person_address_line_1] = (
      patient.address_line_1 unless patient.restricted?
    )
    row[:person_postcode] = (
      patient.address_postcode unless patient.restricted?
    )
    row[:nhs_number] = patient.nhs_number
    row[:consent_status] = consents.first&.response&.humanize
    row[:consent_details] = consent_details(consents:)
    row[:health_question_answers] = Cell.new(
      health_question_answers(consents:),
      style: {
        alignment: {
          wrap_text: true
        }
      }
    )
    row[:triage_status] = triage&.status&.humanize
    row[:triaged_by] = triage&.performed_by&.full_name
    row[:triage_date] = triage&.created_at
    row[:triage_notes] = triage&.notes
    row[:gillick_status] = gillick_status(gillick_assessment:)
    row[:gillick_assessment_date] = gillick_assessment&.created_at
    row[:gillick_assessed_by] = gillick_assessment&.performed_by&.full_name
    row[:gillick_assessment_notes] = gillick_assessment&.notes
  end

  def add_existing_row_cells(row, vaccination_record:)
    row[:vaccinated] = vaccinated(vaccination_record:)
    row[:date_of_vaccination] = vaccination_record.performed_at.to_date
    row[:time_of_vaccination] = vaccination_record.performed_at.strftime(
      "%H:%M:%S"
    )
    row[:programme_name] = vaccination_record.programme.name
    row[:vaccine_given] = vaccination_record.vaccine&.nivs_name
    row[
      :performing_professional_email
    ] = vaccination_record.performed_by_user&.email
    row[:batch_number] = vaccination_record.batch&.name
    row[:batch_expiry_date] = vaccination_record.batch&.expiry
    row[:anatomical_site] = anatomical_site(vaccination_record:)
    row[:dose_sequence] = dose_sequence(vaccination_record:)
    row[:reason_not_vaccinated] = reason_not_vaccinated(vaccination_record:)
    row[:notes] = vaccination_record.notes
    row[:uuid] = vaccination_record.uuid

    if location.generic_clinic?
      row[:clinic_name] = vaccination_record.location_name
    end
  end

  def add_new_row_cells(row, programme:)
    row[:date_of_vaccination] = Cell.new(type: :date)
    row[:programme_name] = programme.name
    row[:batch_expiry_date] = Cell.new(type: :date)
    row[:dose_sequence] = 1 # TODO: revisit this for other programmes
  end

  class CachedStyles
    attr_reader :workbook

    def initialize(workbook)
      @workbook = workbook
      @cache = {}
    end

    def find_or_create(attributes)
      @cache[attributes] ||= workbook.styles.add_style(attributes)
    end
  end

  class Row
    attr_reader :columns, :row_style, :cells

    def initialize(columns, style: {})
      @columns = columns
      @row_style = style
      @cells = columns.map { Cell.new }
      yield self if block_given?
    end

    def []=(column, value)
      index = columns.index(column)
      raise "Column #{column} not in row." if index.nil?

      @cells[index] = (value.is_a?(Cell) ? value : Cell.new(value))
    end

    def add_to(sheet:, cached_styles:)
      values = cells.map(&:value)
      types = cells.map(&:type)
      style =
        cells.map { cached_styles.find_or_create(row_style.merge(_1.style)) }
      sheet.add_row(values, types:, style:)
    end
  end

  class Cell
    attr_reader :value, :type, :style

    def initialize(value = "", type: nil, style: {})
      @value = value
      @type = type || Cell.default_type_for(value)
      @style = Cell.default_style_for(@type).merge(style)
    end

    def self.default_type_for(value)
      case value
      when Date
        :date
      when Integer
        :integer
      else
        :string
      end
    end

    def self.default_style_for(type)
      if type == :date
        { format_code: "dd/mm/yyyy" }
      else
        {}
      end
    end
  end
end
