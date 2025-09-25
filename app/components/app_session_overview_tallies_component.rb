# frozen_string_literal: true

class AppSessionOverviewTalliesComponent < ViewComponent::Base
  def initialize(session)
    @session = session
  end

  private

  attr_reader :session

  delegate :govuk_table, to: :helpers
  delegate :academic_year, :location, :programmes, to: :session

  def cards_for_programme(programme)
    [
      {
        heading: "Eligible cohort",
        colour: "blue",
        count: eligible_cohort_count(programme).to_s
      },
      {
        heading: "Vaccinated",
        colour: "green",
        count: vaccinated_count(programme).to_s,
        link_to:
          session_patients_path(
            session,
            vaccination_status: "vaccinated",
            programme_types: [programme.type]
          )
      },
      {
        heading: "Could not vaccinate",
        colour: "red",
        count: could_not_vaccinate_count(programme).to_s,
        link_to:
          session_patients_path(
            session,
            vaccination_status: "could_not_vaccinate",
            programme_types: [programme.type]
          )
      },
      {
        heading: "No outcome",
        colour: "grey",
        count: no_outcome_count(programme).to_s,
        link_to:
          session_patients_path(
            session,
            vaccination_status: "none_yet",
            programme_types: [programme.type]
          )
      }
    ]
  end

  def eligible_patients(programme)
    session
      .patients
      .appear_in_programmes([programme], academic_year:)
      .eligible_for_programmes([programme], location:, academic_year:)
  end

  def eligible_cohort_count(programme)
    eligible_patients(programme).count
  end

  def vaccinated_count(programme)
    eligible_patients(programme).has_vaccination_status(
      "vaccinated",
      programme:,
      academic_year:
    ).count
  end

  def could_not_vaccinate_count(programme)
    eligible_patients(programme).has_vaccination_status(
      "could_not_vaccinate",
      programme:,
      academic_year:
    ).count
  end

  def no_outcome_count(programme)
    eligible_patients(programme).has_vaccination_status(
      "none_yet",
      programme:,
      academic_year:
    ).count
  end
end
