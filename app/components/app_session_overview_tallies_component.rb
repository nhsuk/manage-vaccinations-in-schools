# frozen_string_literal: true

class AppSessionOverviewTalliesComponent < ViewComponent::Base
  def initialize(session)
    @session = session
    @patient_ids = session.patients.pluck(:id)
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

  private

  def eligible_for_vaccination_count(programme)
    @eligible_for_vaccination_count ||= {}
    @eligible_for_vaccination_count[
      programme.id
    ] ||= patients_in_programme_cohort_count(programme) -
      previously_vaccinated_count(programme) -
      vaccinated_at_different_locations_count(programme)
  end

  def vaccinated_count(programme)
    [
      0,
      administered_vaccination_count(programme) -
        previously_vaccinated_count(programme)
    ].max
  end

  def could_not_vaccinate_count(programme)
    patients_for_programme(programme).has_vaccination_status(
      :could_not_vaccinate,
      programme:,
      academic_year:
    ).count
  end

  def no_outcome_count(programme)
    patients_for_programme(programme).has_vaccination_status(
      :none_yet,
      programme:,
      academic_year:
    ).count
  end

  def patients_in_programme_cohort_count(programme)
    @patients_in_programme_cohort ||= {}
    @patients_in_programme_cohort[programme.id] ||= patients_for_programme(
      programme
    ).appear_in_programmes(programme, academic_year:).count
  end

  def previously_vaccinated_count(programme)
    return 0 if programme.seasonal?

    @previously_vaccinated_count ||= {}
    @previously_vaccinated_count[programme.id] ||= patients_for_programme(
      programme
    ).has_vaccination_status(
      :vaccinated,
      programme:,
      academic_year: academic_year - 1
    ).count
  end

  def administered_vaccination_count(programme)
    patients_for_programme(programme).has_vaccination_status(
      :vaccinated,
      programme:,
      academic_year:
    ).count
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
        .group_by(&:patient_id)

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
        vaccination_records: vaccination_records.fetch(patient.id, [])
      )
    end
  end

  def patients_for_programme(programme)
    @patients_for_programmes ||= {}
    @patients_for_programmes[programme.id] ||= begin
      birth_academic_years = session.programme_birth_academic_years[programme]
      session.patients.where(birth_academic_year: birth_academic_years)
    end
  end
end
