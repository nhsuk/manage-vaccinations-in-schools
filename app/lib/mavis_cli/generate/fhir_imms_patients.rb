# frozen_string_literal: true

require_relative "../../mavis_cli"

module MavisCLI
  module Generate
    class FhirImmsPatients < Dry::CLI::Command
      desc "Generate FHIR IMMS test patients with vaccination records from CSV data"
      option :organisation,
             aliases: ["-o"],
             default: "R1L",
             desc: "ODS code of organisation to create patients for"
      option :vaccination_percentage,
             aliases: ["-p"],
             type: :integer,
             default: 50,
             desc: "Percentage of patients to create vaccination records for (0-100)"

      def call(organisation:, vaccination_percentage: 50, **)
        MavisCLI.load_rails

        org = Organisation.find_by(ods_code: organisation)
        unless org
          puts "Error: Organisation with ODS code '#{organisation}' not found"
          exit 1
        end

        # Ensure vaccination_percentage is within valid range
        vaccination_percentage = [[0, vaccination_percentage.to_i].max, 100].min

        FhirImmsPatientCreator.new(org, vaccination_percentage: vaccination_percentage).call
      end
    end
  end

  register "generate", aliases: ["g"] do |prefix|
    prefix.register "fhir-imms-patients", Generate::FhirImmsPatients
  end
end

class FhirImmsPatientCreator
  CSV_FILE_PATH = File.join(__dir__, "../data/fhir_imms_patients.csv")

  # Default percentage of vaccination records to create (50%)
  DEFAULT_VACCINATION_PERCENTAGE = 50

  def initialize(organisation, vaccination_percentage: DEFAULT_VACCINATION_PERCENTAGE)
    @organisation = organisation
    @programmes = Programme.all.to_a
    @created_patients = []
    @created_vaccination_records = []
    @errors = []
    @skipped_patients = []
    @vaccination_percentage = vaccination_percentage
    ensure_organisation_has_user
  end

  def call
    puts "Starting FHIR IMMS patient creation from CSV data"
    puts "Organisation: #{@organisation.name} (#{@organisation.ods_code})"
    puts "Available programmes: #{@programmes.map(&:name).join(", ")}"
    puts "Vaccination records creation percentage: #{@vaccination_percentage}%"
    puts

    csv_data = read_csv_file

    progress_bar = MavisCLI.progress_bar(csv_data.size)

    csv_data.each do |row|
      create_patient_from_row(row)
      progress_bar.increment
    end

    create_vaccination_records_for_all_patients

    print_summary
  end

  private

  def ensure_organisation_has_user
    return if @organisation.users.any?

    # Create a default user for the organisation
    user =
      User.create!(
        email: "test.user@#{@organisation.ods_code.downcase}.nhs.uk",
        given_name: "Test",
        family_name: "User",
        uid: SecureRandom.uuid
      )

    @organisation.users << user
  end

  def read_csv_file
    unless File.exist?(CSV_FILE_PATH)
      raise "CSV file not found: #{CSV_FILE_PATH}"
    end

    # Read the file and remove BOM if present
    content = File.read(CSV_FILE_PATH, encoding: "UTF-8")
    content = content.gsub(/\A\uFEFF/, "") # Remove BOM

    CSV.parse(content, headers: true, encoding: "UTF-8")
  rescue => e
    puts "Error reading CSV file: #{e.message}"
    raise
  end

  def create_patient_from_row(row)
    # Parse the CSV row data
    nhs_number = row["CHILD_NHS_NUMBER"]&.strip
    given_name = row["CHILD_FIRST_NAME"]&.strip
    family_name = row["CHILD_LAST_NAME"]&.strip
    preferred_given_name = row["CHILD_PREFERRED_FIRST_NAME"]&.strip
    date_of_birth = parse_date(row["CHILD_DATE_OF_BIRTH"])
    gender = parse_gender(row["CHILD_GENDER"])

    # Address fields
    address_line_1 = row["CHILD_ADDRESS_LINE_1"]&.strip
    address_line_2 = row["CHILD_ADDRESS_LINE_2"]&.strip
    address_town = row["CHILD_TOWN"]&.strip
    address_postcode = row["CHILD_POSTCODE"]&.strip

    # School URN
    school_urn = row["CHILD_SCHOOL_URN"]&.strip

    # Skip if essential data is missing
    if given_name.blank? || family_name.blank? || date_of_birth.nil?
      @errors << "Skipping row - missing essential data: #{row.to_h}"
      return
    end

    # Skip if birth date is too old (before 1990 academic year)
    birth_academic_year = date_of_birth.academic_year
    if birth_academic_year < 1990
      @skipped_patients << "#{given_name} #{family_name} - birth year #{birth_academic_year} is before 1990"
      return
    end

    # Check if patient already exists
    existing_patient =
      Patient.find_by(nhs_number: nhs_number) if nhs_number.present?
    if existing_patient
      @skipped_patients << "#{given_name} #{family_name} - patient already exists with NHS number #{nhs_number}"
      return
    end

    # Find school by URN
    school = find_school_by_urn(school_urn) if school_urn.present?

    # Create the patient
    patient =
      Patient.create!(
        nhs_number: nhs_number.presence,
        given_name: given_name,
        family_name: family_name,
        preferred_given_name: preferred_given_name.presence,
        date_of_birth: date_of_birth,
        birth_academic_year: birth_academic_year,
        gender_code: gender,
        address_line_1: address_line_1.presence,
        address_line_2: address_line_2.presence,
        address_town: address_town.presence,
        address_postcode: address_postcode.presence,
        school: school,
        home_educated: nil # Always nil since we have a school
      )

    @created_patients << patient
  rescue => e
    @errors << "Error creating patient from row #{row.to_h}: #{e.message}"
  end

  def parse_date(date_string)
    return nil if date_string.blank?

    # Handle YYYYMMDD format
    if date_string.match?(/^\d{8}$/)
      Date.strptime(date_string, "%Y%m%d")
    else
      Date.parse(date_string)
    end
  rescue StandardError
    nil
  end

  def parse_gender(gender_string)
    return "not_known" if gender_string.blank?

    case gender_string.downcase.strip
    when "male", "m"
      "male"
    when "female", "f"
      "female"
    when "not specified"
      "not_specified"
    else
      "not_known"
    end
  end

  def find_school_by_urn(urn)
    Location.find_by(urn: urn, type: "school")
  end

  def create_vaccination_records_for_all_patients
    puts "\nCreating vaccination records for #{@created_patients.size} patients..."

    total_records = @created_patients.size * @programmes.size
    progress_bar =
      ProgressBar.create(
        total: total_records,
        format: "%a %b\u{15E7}%i %p%% %t",
        progress_mark: " ",
        remainder_mark: "\u{FF65}"
      )

    @created_patients.each do |patient|
      @programmes.each do |programme|
        create_vaccination_record_for_patient(patient, programme)
        progress_bar.increment
      end
    end
  end

  def create_vaccination_record_for_patient(patient, programme)
    # Randomly skip creating vaccination records based on the configured percentage
    return if rand(100) >= @vaccination_percentage

    # Check if patient is in the right year group for this programme
    patient_year_group = calculate_year_group(patient.date_of_birth)
    unless programme.year_groups.include?(patient_year_group)
      return # Skip if patient is not in the right year group for this programme
    end

    # Find or create a session for this programme
    session = find_or_create_session(programme)

    # Create patient session
    patient_session =
      PatientSession.find_or_create_by!(patient: patient, session: session)

    # Get a vaccine and batch for this programme
    vaccine = programme.vaccines.active.first
    return unless vaccine # Skip if no active vaccine available

    batch = find_or_create_batch(vaccine)

    # Create vaccination record
    session_date = session.dates.first || Date.current
    vaccination_record =
      VaccinationRecord.create!(
        patient: patient,
        programme: programme,
        session: session,
        vaccine: vaccine,
        batch: batch,
        outcome: "administered",
        performed_at: session_date + rand(8..16).hours,
        performed_by_user: @organisation.users.first,
        performed_ods_code: @organisation.ods_code,
        dose_sequence:
          programme.default_dose_sequence || programme.vaccinated_dose_sequence,
        delivery_method: "intramuscular",
        delivery_site: "left_arm_upper_position",
        full_dose: true,
        location_name:
          session.location.generic_clinic? ? "Community Clinic" : nil
      )

    @created_vaccination_records << vaccination_record
  rescue => e
    @errors << "Error creating vaccination record for patient #{patient.id}, programme #{programme.type}: #{e.message}"
  end

  def calculate_year_group(date_of_birth)
    current_academic_year = Date.current.academic_year
    birth_academic_year = date_of_birth.academic_year
    current_academic_year - birth_academic_year - 5
  end

  def find_or_create_session(programme)
    # Try to find an existing session for this programme
    existing_session =
      @organisation
        .sessions
        .includes(:session_dates, :location)
        .joins(:programmes)
        .where(programmes: { id: programme.id })
        .first

    return existing_session if existing_session

    # Create a new session
    session_date = Date.current + rand(1..30).days
    session =
      Session.create!(
        organisation: @organisation,
        location: @organisation.generic_clinic,
        programmes: [programme],
        academic_year: Date.current.academic_year
      )

    # Create session date
    session.session_dates.create!(value: session_date)

    session
  end

  def find_or_create_batch(vaccine)
    existing_batch = vaccine.batches.where(organisation: @organisation).first
    return existing_batch if existing_batch

    Batch.create!(
      name: "BATCH#{rand(1000..9999)}",
      expiry: Date.current + 1.year,
      vaccine: vaccine,
      organisation: @organisation
    )
  end

  def print_summary
    puts "\n" + "=" * 50
    puts "FHIR IMMS PATIENTS GENERATION SUMMARY"
    puts "=" * 50
    puts "Vaccination records creation percentage: #{@vaccination_percentage}%"
    puts "Patients created: #{@created_patients.size}"
    puts "Patients skipped: #{@skipped_patients.size}"
    puts "Vaccination records created: #{@created_vaccination_records.size}"
    puts "Errors encountered: #{@errors.size}"

    if @skipped_patients.any?
      puts "\nSkipped patients:"
      @skipped_patients.each { |patient| puts "  - #{patient}" }
    end

    if @errors.any?
      puts "\nErrors:"
      @errors.each { |error| puts "  - #{error}" }
    end

    puts "\nBreakdown by programme:"
    @programmes.each do |programme|
      count =
        @created_vaccination_records.count { |vr| vr.programme == programme }
      puts "  #{programme.name}: #{count} records"
    end

    puts "\nFHIR IMMS patients generation completed successfully!"
  end
end
