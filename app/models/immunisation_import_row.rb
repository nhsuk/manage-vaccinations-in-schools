# frozen_string_literal: true

class ImmunisationImportRow
  include ActiveModel::Model

  validates :administered, inclusion: [true, false]
  validates :delivery_method, presence: true, if: :administered
  validates :delivery_site, presence: true, if: :administered
  validates :organisation_code,
            presence: true,
            length: {
              maximum: 5
            },
            comparison: {
              equal_to: :valid_ods_code
            }
  validates :recorded_at, presence: true

  validates :school_name, presence: true
  validates :school_urn, presence: true

  validates :patient_first_name, presence: true
  validates :patient_last_name, presence: true
  validates :patient_date_of_birth,
            presence: true,
            comparison: {
              less_than_or_equal_to: -> { Date.current }
            }
  validates :patient_gender_code,
            presence: true,
            inclusion: {
              in: Patient.gender_codes.values
            }
  validates :patient_postcode, presence: true, postcode: true
  validate :zero_or_one_existing_patient

  validates :session_date,
            presence: true,
            format: {
              with: /\A\d{8}\z/
            },
            comparison: {
              less_than_or_equal_to: -> { Date.current.strftime("%Y%m%d") }
            }
  validates :reason,
            presence: true,
            inclusion: {
              in: VaccinationRecord.reasons.keys.map(&:to_sym)
            },
            unless: :administered

  def initialize(data:, campaign:, user:, imported_from:)
    @data = data
    @campaign = campaign
    @user = user
    @imported_from = imported_from
  end

  def to_vaccination_record
    return unless valid?

    # TODO: get dose sequence value from CSV
    # TODO: determine correct vaccine batch

    VaccinationRecord.create_with(
      dose_sequence: 1,
      imported_from: @imported_from,
      recorded_at:,
      user: @user
    ).find_or_create_by!(
      administered:,
      delivery_method:,
      delivery_site:,
      patient_session:,
      reason:,
      batch: @campaign.vaccines.first.batches.first
    )
  end

  def patient
    return unless valid?

    @patient ||=
      find_existing_patients.first ||
        Patient.create!(
          address_postcode: patient_postcode,
          date_of_birth: patient_date_of_birth,
          first_name: patient_first_name,
          gender_code: patient_gender_code,
          imported_from:,
          last_name: patient_last_name,
          location:,
          nhs_number: patient_nhs_number
        )
  end

  def administered
    vaccinated = @data["VACCINATED"]&.downcase

    if vaccinated == "yes"
      true
    elsif vaccinated == "no"
      false
    elsif @data["VACCINE_GIVEN"].present?
      true
    end
  end

  def reason
    {
      "Did Not Attend" => :absent_from_session,
      "Vaccination Contraindicated" => :contraindications,
      "Unwell" => :not_well
    }[
      @data["REASON_NOT_VACCINATED"]&.strip
    ]
  end

  DELIVERY_SITES = {
    "left thigh" => :left_thigh,
    "right thigh" => :right_thigh,
    "left upper arm" => :left_arm_upper_position,
    "right upper arm" => :right_arm_upper_position,
    "left buttock" => :left_buttock,
    "right buttock" => :right_buttock,
    "nasal" => :nose
  }.freeze

  def delivery_site
    DELIVERY_SITES[@data["ANATOMICAL_SITE"]&.downcase]
  end

  def delivery_method
    return unless delivery_site

    if delivery_site == :nose
      :nasal_spray
    else
      :intramuscular
    end
  end

  def recorded_at
    Time.zone.now
  end

  def organisation_code
    @data["ORGANISATION_CODE"]&.strip
  end

  def patient_first_name
    @data["PERSON_FORENAME"]&.strip
  end

  def patient_last_name
    @data["PERSON_SURNAME"]&.strip
  end

  def patient_date_of_birth
    Date.strptime(@data["PERSON_DOB"]&.strip, "%Y%m%d")
  rescue ArgumentError, TypeError
    nil
  end

  PATIENT_GENDER_CODES = {
    "not known" => 0,
    "male" => 1,
    "female" => 2,
    "not specified" => 9
  }.freeze

  def patient_gender_code
    gender_code = @data["PERSON_GENDER_CODE"] || @data["PERSON_GENDER"]
    PATIENT_GENDER_CODES[gender_code&.strip&.downcase]
  end

  def patient_postcode
    if (postcode = @data["PERSON_POSTCODE"]).present?
      UKPostcode.parse(postcode).to_s
    end
  end

  def patient_nhs_number
    @data["NHS_NUMBER"]&.gsub(/\s/, "")&.presence
  end

  def school_name
    @data["SCHOOL_NAME"]&.strip
  end

  def school_urn
    @data["SCHOOL_URN"]&.strip
  end

  def session_date
    @data["DATE_OF_VACCINATION"]&.strip
  end

  private

  attr_reader :imported_from

  def location
    return unless valid?

    @location ||=
      Location.create_with(
        name: school_name,
        imported_from:
      ).find_or_create_by!(urn: school_urn)
  end

  def session
    @session ||=
      @campaign
        .sessions
        .create_with(imported_from:)
        .find_or_create_by!(date: session_date, location:)
  end

  def patient_session
    @patient_session ||=
      PatientSession.create_with(created_by: @user).find_or_create_by!(
        patient:,
        session:
      )
  end

  def valid_ods_code
    @user.team.ods_code
  end

  def find_existing_patients
    @find_existing_patients ||=
      begin
        if patient_nhs_number.present? &&
             (
               patient = Patient.find_by(nhs_number: patient_nhs_number)
             ).present?
          return [patient]
        end

        first_name = patient_first_name
        last_name = patient_last_name
        date_of_birth = patient_date_of_birth
        address_postcode = patient_postcode

        Patient
          .where(first_name:, last_name:, date_of_birth:)
          .or(Patient.where(first_name:, last_name:, address_postcode:))
          .or(Patient.where(first_name:, date_of_birth:, address_postcode:))
          .or(Patient.where(last_name:, date_of_birth:, address_postcode:))
          .to_a
      end
  end

  def zero_or_one_existing_patient
    if find_existing_patients.count >= 2
      errors.add(:patient_first_name, :multiple_duplicate_match)
    end
  end
end