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
      vaccinated: vaccinated_count,
      consent_no_response: consent_count_for("no_response"),
      consent_refused:
        consent_count_for("refused") + consent_count_for("conflicts"),
      consent_given: consent_count_for("given")
    }

    if programme.has_multiple_vaccine_methods?
      programme.vaccine_methods.each do |vaccine_method|
        stats[:"consent_given_#{vaccine_method}"] = consent_count_for(
          "given",
          vaccine_method:
        )
      end
    end

    stats
  end

  def self.call(...) = new(...).call

  private

  attr_reader :session, :programme

  delegate :academic_year, :location, to: :session

  def vaccinated_count
    @vaccinated_count ||=
      Patient::VaccinationStatus
        .vaccinated
        .where(patient_id: patient_ids, programme:, academic_year:)
        .count
  end

  def consent_count_for(status, vaccine_method: nil)
    vaccine_method_value =
      if vaccine_method
        Patient::ConsentStatus.vaccine_methods.fetch(vaccine_method)
      end

    consent_counts.sum do |(counted_status, counted_vaccine_methods), count|
      next 0 unless counted_status == status

      unless vaccine_method_value.nil? ||
               counted_vaccine_methods.include?(vaccine_method_value)
        next 0
      end

      count
    end
  end

  def consent_counts
    @consent_counts ||=
      Patient::ConsentStatus
        .where(patient_id: patient_ids, programme:, academic_year:)
        .group(:status, :vaccine_methods)
        .count
  end

  def patient_ids
    @patient_ids ||=
      session
        .patients
        .not_deceased
        .eligible_for_programmes([programme], location:, academic_year:)
        .pluck(:id)
  end
end
