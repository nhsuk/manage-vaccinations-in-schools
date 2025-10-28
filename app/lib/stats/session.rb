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
        stats[:"consent_given_#{vaccine_method}"] = consent_counts_by_method[
          vaccine_method
        ] || 0
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

  def consent_counts_by_method
    @consent_counts_by_method ||=
      Patient::ConsentStatus
        .where(
          patient_id: patient_ids,
          programme:,
          academic_year:,
          status: "given"
        )
        .joins("CROSS JOIN LATERAL unnest(vaccine_methods) as method_value")
        .group(:method_value)
        .count("DISTINCT patient_consent_statuses.id")
        .transform_keys { Patient::ConsentStatus.vaccine_methods.key(it) }
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
