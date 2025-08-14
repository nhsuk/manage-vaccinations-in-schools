# frozen_string_literal: true

class TeamMigration::EastOfEngland < TeamMigration::Base
  def perform
    create_new_teams
    move_patients_in_generic_clinic
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
        .vaccination_records
        .includes(:batch)
        .find_each do |vaccination_record|
          batch = vaccination_record.batch
          if batch.team_id != team.id
            log("Reassigning batch #{batch.name} to #{team.workgroup}")
            batch.update!(team:)
          end
        end
    end
  end

  def school_rows
    CSV.foreach(__FILE__.gsub(".rb", ".csv"), headers: true)
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
