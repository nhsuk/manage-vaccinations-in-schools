# frozen_string_literal: true

class Stats::Session
  def initialize(session, programme:)
    @session = session
    @programme = programme
    @academic_year = session.academic_year
  end

  def call
    stats = {
      eligible_children: patient_ids.size,
      consent_no_response: consent_count_for("no_response")
    }

    consent_given_statuses.each do |consent_given_status|
      options =
        PatientSearchForm::CONSENT_GIVEN_PREDICATES.fetch(consent_given_status)

      stats[:"consent_#{consent_given_status}"] = consent_count_for(
        "given",
        **options
      )
    end

    stats.merge(
      consent_refused:
        consent_count_for("refused") + consent_count_for("conflicts"),
      vaccinated: vaccinated_count
    )
  end

  def self.call(...) = new(...).call

  private

  attr_reader :session, :programme

  delegate :academic_year, :location, to: :session

  def vaccinated_count
    @vaccinated_count ||=
      Patient::VaccinationStatus
        .vaccinated
        .where_programme(programme)
        .where(patient_id: patient_ids, academic_year:)
        .count
  end

  def consent_given_statuses
    if programme.has_multiple_vaccine_methods?
      %w[given_nasal given_injection_without_gelatine]
    elsif programme.vaccine_may_contain_gelatine?
      %w[given_injection given_injection_without_gelatine]
    else
      %w[given_injection]
    end
  end

  def consent_count_for(status, vaccine_method: nil, without_gelatine: nil)
    vaccine_method_value =
      if vaccine_method
        Patient::ConsentStatus.vaccine_methods.fetch(vaccine_method)
      end

    consent_counts.sum do |(counted_status, counted_vaccine_methods, counted_without_gelatine), count|
      next 0 unless counted_status == status

      unless vaccine_method_value.nil? ||
               counted_vaccine_methods.include?(vaccine_method_value)
        next 0
      end

      unless without_gelatine.nil? ||
               counted_without_gelatine == without_gelatine
        next 0
      end

      count
    end
  end

  def consent_counts
    @consent_counts ||=
      Patient::ConsentStatus
        .where_programme(programme)
        .where(patient_id: patient_ids, academic_year:)
        .group(:status, :vaccine_methods, :without_gelatine)
        .count
  end

  def patient_ids
    @patient_ids ||=
      session
        .patients
        .not_deceased
        .appear_in_programmes([programme], session:)
        .eligible_for_programmes([programme], location:, academic_year:)
        .pluck(:id)
  end
end
