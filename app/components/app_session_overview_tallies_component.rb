# frozen_string_literal: true

class AppSessionOverviewTalliesComponent < ViewComponent::Base
  def initialize(session)
    @session = session
    @patient_ids = session.patient_ids
    @academic_year = session.academic_year
  end

  attr_reader :session, :patient_ids, :academic_year

  delegate :govuk_table, to: :helpers
  delegate :programmes, to: :session

  def tally_cards_for_programme(programme)
    [
      {
        heading: "Eligible cohort",
        colour: "blue",
        count: eligible_for_vaccination_count(programme).to_s,
        link_to: nil
      },
      {
        heading: "Vaccinated",
        colour: "green",
        count: vaccinated_count(programme).to_s,
        link_to:
          session_patients_path(
            @session,
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
            @session,
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
            @session,
            vaccination_status: "none_yet",
            programme_types: [programme.type]
          )
      }
    ]
  end

  private

  def eligible_for_vaccination_count(programme)
    patients_in_programme_cohort(programme).count -
      previously_vaccinated_count(programme) -
      vaccinated_at_different_locations_count(programme)
  end

  def vaccinated_count(programme)
    administered_vaccination_count(programme)
  end

  def could_not_vaccinate_count(programme)
    Patient::VaccinationStatus
      .where(programme:, academic_year:, patient_id: patient_ids)
      .could_not_vaccinate
      .count
  end

  def no_outcome_count(programme)
    Patient::VaccinationStatus
      .where(programme:, academic_year:, patient_id: patient_ids)
      .none_yet
      .count
  end

  def patients_in_programme_cohort(programme)
    session.patients.appear_in_programmes(programme, academic_year:)
  end

  def previously_vaccinated_count(programme)
    return 0 if programme.seasonal?

    Patient::VaccinationStatus
      .where(programme_id: programme.id, patient_id: patient_ids)
      .where("academic_year < ?", academic_year)
      .vaccinated
      .count
  end

  def administered_vaccination_count(programme)
    Patient::VaccinationStatus
      .where(
        academic_year:,
        programme_id: programme.id,
        patient_id: patient_ids
      )
      .vaccinated
      .count
  end

  def vaccinated_at_different_locations_count(programme)
    vaccination_records =
      VaccinationRecord
        .where(
          patient_id: patient_ids,
          programme_id: programme.id,
          outcome: %w[administered already_had]
        )
        .where.not(location: session.location)

    # The VaccinatedCriteria class is responsible for determining whether a
    # patient is considered vaccinated or not. There's some nuance around
    # Td/IPV and MenACWY where a patient may have a vaccination record, but
    # if it's the wrong dose or if the patient was younger than 10 years old
    # it doesn't count.
    session.patients.count do |patient|
      VaccinatedCriteria.call(
        programme:,
        academic_year:,
        patient:,
        vaccination_records:
      )
    end
  end
end
