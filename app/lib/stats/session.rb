# frozen_string_literal: true

class Stats::Session
  def initialize(session:, programme:)
    @session = session
    @programme = programme
    @academic_year = session.academic_year
  end

  def call
    stats = {
      eligible_children: patient_ids.size,
      no_response: consent_count_for("no_response"),
      did_not_consent:
        consent_count_for("refused") + consent_count_for("conflicts"),
      vaccinated: vaccination_count_for("vaccinated"),
      consent_given: consent_count_for("given")
    }

    if programme.has_multiple_vaccine_methods?
      programme.vaccine_methods.each do |vaccine_method|
        stats[:"consent_given_#{vaccine_method}"] = consent_count_with_method(
          patient_ids,
          vaccine_method
        )
      end
    end

    stats
  end

  def self.call(...) = new(...).call

  private

  attr_reader :session, :programme, :academic_year

  def vaccination_count_for(status)
    vaccination_counts[status] || 0
  end

  def consent_count_for(status)
    consent_counts[status] || 0
  end

  def vaccination_counts
    @vaccination_counts ||=
      Patient::VaccinationStatus
        .where(patient_id: patient_ids, programme:, academic_year:)
        .group(:status)
        .count
  end

  def consent_counts
    @consent_counts ||=
      Patient::ConsentStatus
        .where(patient_id: patient_ids, programme:, academic_year:)
        .group(:status)
        .count
  end

  def consent_count_with_method(patient_ids, vaccine_method)
    Patient::ConsentStatus
      .where(
        patient_id: patient_ids,
        programme:,
        academic_year:,
        status: "given"
      )
      .has_vaccine_method(vaccine_method)
      .count
  end

  def patient_ids
    @patient_ids ||=
      session
        .patients
        .not_deceased
        .eligible_for_programmes(
          [programme],
          location: session.location,
          academic_year:
        )
        .pluck(:id)
  end
end
