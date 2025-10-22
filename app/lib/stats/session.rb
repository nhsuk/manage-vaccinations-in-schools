# frozen_string_literal: true

class Stats::Session
  def initialize(session:, programme:)
    @session = session
    @programme = programme
    @academic_year = session.academic_year
  end

  def call
    stats = {
      eligible_children: eligible_patients.count,
      no_response: consent_count("no_response"),
      did_not_consent: consent_count(%w[refused conflicts]),
      vaccinated: vaccinated_count
    }

    if programme.has_multiple_vaccine_methods?
      programme.vaccine_methods.each do |vaccine_method|
        stats[:"consent_given_#{vaccine_method}"] = consent_given_count(
          vaccine_method:
        )
      end
    else
      stats[:consent_given] = consent_given_count
    end

    stats
  end

  def self.call(...) = new(...).call

  private

  attr_reader :session, :programme, :academic_year

  def vaccinated_count
    eligible_patients.has_vaccination_status(
      "vaccinated",
      programme:,
      academic_year:
    ).count
  end

  def consent_given_count(vaccine_method: nil)
    consent_count("given", vaccine_method:)
  end

  def consent_count(status, vaccine_method: nil)
    eligible_patients.has_consent_status(
      status,
      programme:,
      academic_year:,
      vaccine_method:
    ).count
  end

  def eligible_patients
    session
      .patients
      .not_deceased
      .appear_in_programmes([programme], session:)
      .eligible_for_programmes(
        [programme],
        location: session.location,
        academic_year:
      )
  end
end
