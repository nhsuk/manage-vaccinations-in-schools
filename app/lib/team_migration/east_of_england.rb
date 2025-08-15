# frozen_string_literal: true

class TeamMigration::EastOfEngland < TeamMigration::Base
  def perform
    create_new_teams
    move_patients_in_generic_clinic
    reassign_class_imports
    reassign_cohort_imports
    reassign_immunisation_imports
    reassign_consent_forms
    reassign_batches
    reassign_consents_and_triages
    destroy_old_team
  end

  private

  def ods_code = "RY4"

  def current_team
    @current_team ||=
      Team.find_by!(
        name:
          "Hertfordshire and East Anglia Community School Age Immunisation Service",
        organisation:
      )
  end

  def flu_programme
    @flu_programme ||= Programme.find_by!(type: "flu")
  end

  def hpv_programme
    @hpv_programme ||= Programme.find_by!(type: "hpv")
  end

  def create_new_teams
    school_rows.each do |row|
      urn = row.fetch("URN")
      sen = row.fetch("SEN") == "SEN"
      team = teams.fetch(row.fetch("ICB Shortname"))

      process_row(urn, sen, team)
    end
  end

  def move_patients_in_generic_clinic
    academic_year = AcademicYear.current

    old_session = current_team.generic_clinic_session(academic_year:)

    new_sessions =
      teams.values.index_with do |team|
        team.generic_clinic_session(academic_year:)
      end

    old_session
      .patient_sessions
      .includes(patient: { school: :team })
      .find_each do |patient_session|
        patient = patient_session.patient

        if patient.school_id.nil?
          # There are a small number of patients with an unknown school. We're
          # going to send the team a list of these before migrating and remove
          # them from the community clinic for now.
          log("Removing patient #{patient.id} from community clinics")
          patient_session.destroy!
        else
          session_id = new_sessions.fetch(patient.school.team).id
          patient_session.update_column(:session_id, session_id)
        end
      end

    old_session.location.strict_loading!(false)
    old_session.location.destroy!
    old_session.destroy!
  end

  def reassign_class_imports
    ClassImport
      .where(team: current_team)
      .includes(location: :team)
      .find_each do |class_import|
        new_team = class_import.location.team
        log(
          "Reassigning class import #{class_import.id} to #{new_team.workgroup}"
        )
        class_import.update!(team: new_team)
      end
  end

  def reassign_cohort_imports
    CohortImport
      .where(team: current_team)
      .includes(patients: :teams)
      .find_each do |cohort_import|
        new_team =
          cohort_import.patients.flat_map(&:teams).find { it.id.in?(team_ids) }

        if new_team.nil?
          log("No team for cohort import #{cohort_import.csv_filename}")
          cohort_import.destroy!
        else
          log(
            "Reassigning cohort import #{cohort_import.id} to #{new_team.workgroup}"
          )
          cohort_import.update!(team: new_team)
        end
      end
  end

  def reassign_immunisation_imports
    ImmunisationImport
      .where(team: current_team)
      .includes(patients: :teams)
      .find_each do |immunisation_import|
        new_team =
          immunisation_import
            .patients
            .flat_map(&:teams)
            .find { it.id.in?(team_ids) }

        if new_team.nil?
          log(
            "No team for immunisation import #{immunisation_import.csv_filename}"
          )
          immunisation_import.destroy!
        else
          log(
            "Reassigning immunisation import #{immunisation_import.id} to #{new_team.workgroup}"
          )
          immunisation_import.update!(team: new_team)
        end
      end
  end

  def reassign_consent_forms
    current_team
      .consent_forms
      .includes(location: :team)
      .find_each do |consent_form|
        new_team = consent_form.location.team
        log(
          "Reassigning consent form #{consent_form.id} to #{new_team.workgroup}"
        )
        consent_form.update_column(:team_id, new_team.id)
      end
  end

  def reassign_batches
    # There are around 2695 vaccination records that are assigned a batch but
    # not a session, and therefore no location. We can't easily determine the
    # team they belong to without guessing based on some other information
    # which is what this is doing.

    reassign_by_patient_session_count = 0
    reassign_by_location_name_count = 0
    reassign_by_patient_school_count = 0
    destroyed_count = 0

    # First let's try to re-assign batches based on the patient's session's location.

    VaccinationRecord
      .where(batch: Batch.where(team: current_team))
      .includes(patient: { sessions: :team })
      .find_each do |vaccination_record|
        session =
          vaccination_record.patient.sessions.find { it.team_id.in?(team_ids) }

        team = session&.team
        batch = vaccination_record.batch

        if team && batch.team_id != team.id
          log("Reassigning batch #{batch.name} to #{team.workgroup}")
          batch.update!(team:)
        end

        reassign_by_patient_session_count += 1
      end

    # Next let's try to re-assign batches based on the location name.

    VaccinationRecord
      .where(batch: Batch.where(team: current_team))
      .find_each do |vaccination_record|
        locations =
          Location
            .school
            .joins(:subteam)
            .includes(subteam: :team)
            .where(subteam: { team_id: team_ids })
            .where(name: vaccination_record.location_name)

        location = locations.first if locations.count == 1
        team = location&.subteam&.team
        batch = vaccination_record.batch

        if team && batch.team_id != team.id
          log("Reassigning batch #{batch.name} to #{team.workgroup}")
          batch.update!(team:)
        end

        reassign_by_location_name_count += 1
      end

    # Next let's try to re-assign batches based on the patient's school.

    VaccinationRecord
      .includes(patient: { school: :team })
      .where(batch: Batch.where(team: current_team))
      .find_each do |vaccination_record|
        team = vaccination_record.patient&.school&.team
        batch = vaccination_record.batch

        if team && team.id.in?(team_ids) && batch.team_id != team.id
          log("Reassigning batch #{batch.name} to #{team.workgroup}")
          batch.update!(team:)
        end

        reassign_by_patient_school_count += 1
      end

    # If there are any left we have to destroy the batch and add the number to the notes.

    Batch
      .where(team: current_team)
      .find_each do |batch|
        VaccinationRecord
          .where(batch:)
          .find_each do |vaccination_record|
            notes = [
              vaccination_record.notes,
              "Batch: #{batch.name}"
            ].compact_blank.join("\n")
            log(
              "Clearing batch for vaccination record #{vaccination_record.id} " \
                "(patient #{vaccination_record.patient_id})"
            )
            vaccination_record.update!(batch: nil, notes:)
          end

        log("Destroying unused batch #{batch.name} (#{batch.id})")
        batch.destroy!

        destroyed_count += 1
      end

    log(
      "Batches reassigned: " \
        "#{reassign_by_patient_session_count} were determined from patient sessions, " \
        "#{reassign_by_location_name_count} were determined from location name, " \
        "#{reassign_by_patient_school_count} were determined by patient school, " \
        "#{destroyed_count} were destroyed"
    )
  end

  def reassign_consents_and_triages
    # Some unknown school patients have been removed from cohort but have
    # consents and triages. We find the school they used to belong at some
    # point and assign it to that team.

    Consent
      .includes(patient: :audits)
      .where(team: current_team)
      .find_each do |consent|
        team = determine_team_for_patient(consent.patient)
        log("Reassigning consent #{consent.id} to #{team.workgroup}")
        consent.update!(team:)
      end

    Triage
      .includes(patient: :audits)
      .where(team: current_team)
      .find_each do |triage|
        team = determine_team_for_patient(triage.patient)
        log("Reassigning triage #{triage.id} to #{team.workgroup}")
        triage.update!(team:)
      end
  end

  def destroy_old_team
    destroy_team(current_team)
  end

  def process_row(urn, sen, team)
    location = Location.school.find_by!(urn:)
    attach_school_to_team(location, team)

    programmes = (sen ? [flu_programme, hpv_programme] : [hpv_programme])
    add_school_year_groups(location, programmes, sen:)

    location.sessions.find_each do |session|
      log("Reassigning session to #{team.workgroup}")
      session.update!(team:)

      session
        .patients
        .includes(:consents, :triages)
        .find_each do |patient|
          log(
            "Reassigning consents and triages of #{patient.id} to #{team.workgroup}"
          )
          patient
            .consents
            .where(team: current_team)
            .update_all(team_id: team.id)
          patient.triages.where(team: current_team).update_all(team_id: team.id)
        end

      session
        .vaccination_records
        .includes(:batch)
        .find_each do |vaccination_record|
          batch = vaccination_record.batch
          if batch && batch.team_id != team.id
            log("Reassigning batch #{batch.name} to #{team.workgroup}")
            batch.update!(team:)
          end
        end
    end
  end

  def school_rows
    CSV.foreach(
      "/rails/app/lib/team_migration/east_of_england.csv",
      headers: true
    )
  end

  def teams
    @teams ||=
      TEAMS.transform_values do |attributes|
        team =
          create_team(
            **attributes,
            careplus_venue_code: "UNUSED",
            privacy_notice_url: "https://www.hct.nhs.uk/privacy",
            privacy_policy_url: "https://www.hct.nhs.uk/privacy"
          )
        add_team_programmes(team, "flu", "hpv")
        team
      end
  end

  def team_ids
    @team_ids ||= teams.values.map(&:id)
  end

  def determine_team_for_patient(patient)
    school_ids =
      patient.audits.filter_map do |audit|
        Array(audit.audited_changes["school_id"]).compact.last
      end

    school =
      Location
        .school
        .includes(subteam: :team)
        .joins(:subteam)
        .where(subteam: { team_id: team_ids }, id: school_ids)
        .first

    school&.subteam&.team
  end

  TEAMS = {
    "BLMK ICB" => {
      workgroup: "bedslutonmiltonkeynessais",
      name:
        "Bedfordshire, Luton and Milton Keynes School Age Immunisation Service",
      email: "hct.csaisblmk@nhs.net",
      phone: "0300 555 5055",
      phone_instructions: "option 5"
    },
    "C&P ICB" => {
      workgroup: "cambridgepeterboroughsais",
      name: "Cambridgeshire and Peterborough School Age Immunisation Service",
      email: "hct.csaiscambpb@nhs.net",
      phone: "0300 555 5055",
      phone_instructions: "option 4"
    },
    "HWE ICB" => {
      workgroup: "hertswestessexsais",
      name: "Hertfordshire and West Essex School Age Immunisation Service",
      email: "hct.csaishwe@nhs.net",
      phone: "0300 555 5055",
      phone_instructions: "option 7"
    },
    "MSE ICB" => {
      workgroup: "midsouthessexsais",
      name: "Mid and South Essex School Age Immunisation Service",
      email: "hct.csaismse@nhs.net",
      phone: "0300 555 5055",
      phone_instructions: "option 6"
    },
    "N&W ICB" => {
      workgroup: "norfolkwaveneysais",
      name: "Norfolk and Waveney School Age Immunisation Service",
      email: "hct.csaisnorfolk@nhs.net",
      phone: "0300 555 5055",
      phone_instructions: "option 2"
    },
    "SNEE ICB" => {
      workgroup: "suffolknortheastessexsais",
      name: "Suffolk and North East Essex School Age Immunisation Service",
      email: "hct.csaissnee@nhs.net",
      phone: "0300 555 5055",
      phone_instructions: "option 3"
    }
  }.freeze
end
