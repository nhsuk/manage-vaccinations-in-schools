# frozen_string_literal: true

##
# This class handles all the business logic related to determining whether a
# patient should be considered vaccinated for a particular programme type and
# academic year.
#
# This reason this exists outside the +StatusGenerator+ module is that it is
# used by each of the status generators but is not a status by itself.
class VaccinationCriteria
  ##
  # Create a new instance of the class for the +programme_type+,
  # +academic_year+, and +patient+.
  #
  # The +vaccination_records+ argument is required to allow for a preloaded
  # array to be passed in, rather than fetching the records from the database.
  # Any vaccination records can be passed in and will be filtered on the
  # patient, programme type, and academic year. The filtered list is then
  # available to read back as the +vaccination_records+ method on the
  # class instance.
  def initialize(
    programme_type:,
    academic_year:,
    patient:,
    vaccination_records:
  )
    @programme_type = programme_type
    @academic_year = academic_year
    @patient = patient

    @vaccination_records =
      vaccination_records.select do
        it.patient_id == patient.id && it.programme_type == programme_type &&
          if programme.seasonal?
            it.academic_year == academic_year
          else
            it.academic_year <= academic_year
          end
      end
  end

  ##
  # Returns +true+ if the patient should be considered vaccinated.
  def vaccinated? = vaccinated_vaccination_record != nil

  ##
  # Returns the first vaccination record that confirms that the patient is
  # vaccinated.
  def vaccinated_vaccination_record
    @vaccinated_vaccination_record ||=
      begin
        if (already_had_record = valid_vaccination_records.find(&:already_had?))
          return already_had_record
        end

        if programme.mmr?
          if valid_vaccination_records.count >= programme.maximum_dose_sequence
            valid_vaccination_records.first
          end
        elsif programme.td_ipv?
          valid_vaccination_records.find do
            it.dose_sequence == 5 || it.sourced_from_service?
          end
        else
          valid_vaccination_records.first
        end
      end
  end

  ##
  # Returns the administered vaccination records that are considered valid
  # doses according to the specific criteria of the programme.
  def valid_vaccination_records
    @valid_vaccination_records ||=
      if programme.seasonal?
        vaccination_records.select { it.administered? || it.already_had? }
      else
        if (
             already_had_records = vaccination_records.select(&:already_had?)
           ).present?
          return already_had_records
        end

        administered_records = vaccination_records.select(&:administered?)

        if programme.doubles?
          filter_doubles_vaccination_records(administered_records)
        elsif programme.hpv?
          filter_hpv_vaccination_records(administered_records)
        elsif programme.mmr?
          filter_mmr_vaccination_records(administered_records)
        else
          raise UnsupportedProgrammeType, programme_type
        end
      end
  end

  attr_reader :vaccination_records

  private

  attr_reader :programme_type, :academic_year, :patient

  def filter_doubles_vaccination_records(vaccination_records)
    vaccination_records.select { patient.age_years(now: it.performed_at) >= 10 }
  end

  def filter_hpv_vaccination_records(vaccination_records)
    vaccination_records
  end

  def filter_mmr_vaccination_records(vaccination_records)
    # Any child who hasn't had two doses of MMR with the first dose above 1
    # year of age and the second above 15 months and the doses at least 4
    # weeks apart is eligible for catch up vaccinations by SAIS until they
    # have had two valid doses.

    sorted_vaccination_records = vaccination_records.sort_by(&:performed_at)

    first_dose =
      sorted_vaccination_records.find do
        patient.age_months(now: it.performed_at) >= 12
      end

    return [] if first_dose.nil?

    # The second dose must be at least 28 days after the most recent dose
    second_dose =
      sorted_vaccination_records.find do |record|
        next if record.performed_at <= first_dose.performed_at

        previous_dose =
          sorted_vaccination_records
            .select { it.performed_at < record.performed_at }
            .last

        record.performed_at >= previous_dose.performed_at + 28.days &&
          patient.age_months(now: record.performed_at) >= 15
      end

    [second_dose, first_dose].compact
  end

  def programme
    @programme ||= Programme.find(programme_type)
  end
end
