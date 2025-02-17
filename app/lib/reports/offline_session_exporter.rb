# frozen_string_literal: true

class Reports::OfflineSessionExporter
  include Reports::ExportFormatters

  def initialize(session)
    @session = session
    @vaccines = {}
    @batches = {}
  end

  def call
    # stree-ignore
    Axlsx::Package
      .new { |package|
        package.use_shared_strings = true

        add_vaccinations_sheet(package)
        add_reference_sheet package,
                            name: "Performing Professionals",
                            values_name: "EMAIL",
                            values: performing_professional_email_values
        add_batch_numbers_sheets(package)
      }
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

  def add_reference_sheet(package, name:, values_name:, values:)
    workbook = package.workbook
    workbook.add_worksheet(name:, state: :hidden) do |sheet|
      sheet.sheet_protection

      sheet.add_row([values_name])

      values.each { |value| sheet.add_row([value]) }
    end
  end

  def add_batch_numbers_sheets(package)
    session.programmes.map do |programme|
      add_reference_sheet package,
                          name: "#{programme.type} Batch Numbers",
                          values_name: "NUMBER",
                          values: batch_values_for_programme(programme)
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
      .eager_load(patient: :school)
      .preload(
        :programmes,
        patient: {
          consents: [:parent, { patient: :parent_relationships }],
          triages: :performed_by,
          vaccination_records: %i[batch performed_by_user vaccine]
        },
        gillick_assessments: :performed_by
      )
      .order_by_name
  end

  def rows(patient_session:)
    bg_color =
      if patient_session.consent_refused?
        "F7D4D1"
      elsif patient_session.consent_conflicts?
        "FFDC8E"
      end

    row_style = {
      strike: patient_session.patient.invalidated?,
      bg_color:,
      border: {
        style: :thin,
        color: "000000"
      }
    }

    session.programmes.flat_map do |programme|
      vaccination_records =
        patient_session.vaccination_records(programme:, for_session: true)

      if vaccination_records.any?
        vaccination_records.map do |vaccination_record|
          Row.new(columns, style: row_style) do |row|
            add_patient_cells(row, patient_session:, programme:)
            add_existing_row_cells(row, vaccination_record:)
          end
        end
      else
        [
          Row.new(columns, style: row_style) do |row|
            add_patient_cells(row, patient_session:, programme:)
            add_new_row_cells(row, programme:)
          end
        ]
      end
    end
  end

  def add_patient_cells(row, patient_session:, programme:)
    patient = patient_session.patient

    gillick_assessment = patient_session.gillick_assessment(programme:)
    consents = patient_session.latest_consents(programme:)
    triage = patient_session.latest_triage(programme:)

    row[:organisation_code] = organisation.ods_code
    row[:school_urn] = school_urn(location:, patient:)
    row[:school_name] = school_name(location:, patient:)
    row[:care_setting] = Cell.new(
      care_setting(location:),
      type: :integer,
      allowed_values: [1, 2]
    )
    row[:person_forename] = patient.given_name
    row[:person_surname] = patient.family_name
    row[:person_dob] = patient.date_of_birth
    row[:year_group] = patient.year_group
    row[:person_gender_code] = Cell.new(
      patient.gender_code.humanize,
      allowed_values: Patient.gender_codes.keys
    )
    row[:person_address_line_1] = (
      patient.address_line_1 unless patient.restricted?
    )
    row[:person_postcode] = (
      patient.address_postcode unless patient.restricted?
    )
    row[:nhs_number] = patient.nhs_number
    row[:consent_status] = consent_status(patient_session:)
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
    batch = vaccination_record.batch
    programme = vaccination_record.programme
    vaccine = vaccination_record.vaccine

    row[:vaccinated] = Cell.new(
      vaccinated(vaccination_record:),
      allowed_values: %w[Y N]
    )
    row[:date_of_vaccination] = vaccination_record.performed_at.to_date
    row[:time_of_vaccination] = vaccination_record.performed_at.strftime(
      "%H:%M:%S"
    )
    row[:programme_name] = programme.name
    row[:vaccine_given] = Cell.new(
      vaccine&.nivs_name,
      allowed_values: vaccine_values_for_programme(programme)
    )
    row[:performing_professional_email] = Cell.new(
      vaccination_record.performed_by_user&.email,
      allowed_formula: performing_professionals_range
    )
    row[:batch_number] = Cell.new(
      batch&.name,
      allowed_formula: batch_numbers_range_for_programme(programme)
    )
    row[:batch_expiry_date] = batch&.expiry
    row[:anatomical_site] = Cell.new(
      anatomical_site(vaccination_record:),
      allowed_values: ImmunisationImportRow::DELIVERY_SITES.keys
    )
    row[:dose_sequence] = dose_sequence(vaccination_record:)
    row[:reason_not_vaccinated] = Cell.new(
      reason_not_vaccinated(vaccination_record:),
      allowed_values: ImmunisationImportRow::REASONS.keys
    )
    row[:notes] = vaccination_record.notes
    row[:uuid] = vaccination_record.uuid

    if location.generic_clinic?
      row[:clinic_name] = Cell.new(
        vaccination_record.location_name,
        allowed_values: clinic_name_values
      )
    end
  end

  def add_new_row_cells(row, programme:)
    row[:vaccinated] = Cell.new(allowed_values: %w[Y N])
    row[:date_of_vaccination] = Cell.new(type: :date)
    row[:programme_name] = programme.name
    row[:vaccine_given] = Cell.new(
      allowed_values: vaccine_values_for_programme(programme)
    )
    row[:performing_professional_email] = Cell.new(
      allowed_formula: performing_professionals_range
    )
    row[:batch_number] = Cell.new(
      allowed_formula: batch_numbers_range_for_programme(programme)
    )
    row[:batch_expiry_date] = Cell.new(type: :date)
    row[:anatomical_site] = Cell.new(
      allowed_values: ImmunisationImportRow::DELIVERY_SITES.keys
    )
    row[:dose_sequence] = 1 # TODO: revisit this for other programmes
    row[:reason_not_vaccinated] = Cell.new(
      allowed_values: ImmunisationImportRow::REASONS.keys
    )

    if location.generic_clinic?
      row[:clinic_name] = Cell.new(allowed_values: clinic_name_values)
    end
  end

  def vaccine_values_for_programme(programme)
    @vaccines[programme] ||= Vaccine.active.where(programme:).pluck(:nivs_name)
  end

  def batch_values_for_programme(programme, existing_batch: nil)
    batch_names =
      (
        @batches[programme] ||= organisation
          .batches
          .not_archived
          .not_expired
          .joins(:vaccine)
          .where(vaccine: { programme: })
          .pluck(:name)
      )

    (batch_names + [existing_batch&.name].compact).uniq
  end

  def performing_professional_email_values
    @performing_professional_email_values ||=
      User
        .joins(:organisations)
        .where(organisations: organisation)
        .pluck(:email)
  end

  def performing_professionals_range
    count = performing_professional_email_values.count
    "'Performing Professionals'!$A2:$A#{count + 1}"
  end

  def batch_numbers_range_for_programme(programme)
    count = batch_values_for_programme(programme).count
    "'#{programme.type} Batch Numbers'!$A2:$A#{count + 1}"
  end

  def clinic_name_values
    @clinic_name_values =
      Location
        .community_clinic
        .joins(:team)
        .where(team: { organisation: })
        .pluck(:name)
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
      row_index = sheet.rows.count

      values = cells.map(&:value)
      types = cells.map(&:type)
      style =
        cells.map { cached_styles.find_or_create(row_style.merge(_1.style)) }
      sheet.add_row(values, types:, style:)

      cells.each_with_index do |cell, column_index|
        cell.add_data_validation_to(sheet:, row_index:, column_index:)
      end
    end
  end

  class Cell
    attr_reader :value, :type, :style, :allowed_values, :allowed_formula

    def initialize(
      value = "",
      type: nil,
      style: {},
      allowed_values: [],
      allowed_formula: nil
    )
      @value = value
      @type = type || Cell.default_type_for(value)
      @style = Cell.default_style_for(@type).merge(style)
      @allowed_values = allowed_values
      @allowed_formula = allowed_formula
    end

    ALPHABET = %w[A B C D E F G H I J K L M N O P Q R S T U V W X Y Z].freeze
    CELL_COLUMNS = ALPHABET + ALPHABET.product(ALPHABET).map { _1 + _2 }

    def add_data_validation_to(sheet:, column_index:, row_index:)
      return if allowed_values.blank? && allowed_formula.blank?

      cell = "#{CELL_COLUMNS[column_index]}#{row_index + 1}"
      formula1 =
        if allowed_values.present?
          "\"#{allowed_values.join(", ")}\""
        elsif allowed_formula.present?
          "=#{allowed_formula}"
        end

      sheet.add_data_validation(
        cell,
        type: :list,
        formula1:,
        hideDropDown: false,
        showErrorMessage: true,
        errorTitle: "",
        error: "Please use the dropdown selector to choose the value",
        errorStyle: :stop,
        showInputMessage: true,
        prompt: "&amp; Choose the value from the dropdown"
      )
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
