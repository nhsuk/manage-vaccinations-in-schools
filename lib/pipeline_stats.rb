#!/usr/bin/env ruby

class PipelineStats
  class PatientCollection
    attr_reader :organisation, :patients, :programme

    delegate :count, :first, :pluck, :sample, :to_sql, :uniq, to: :patients

    def initialize(patients, organisation: nil, programme: nil)
      @patients = patients
      @organisation = organisation
      @programme = programme
    end

    def replicate(patients)
      self.class.new(
        patients,
        organisation: @organisation,
        programme: @programme
      )
    end

    def in_organisation(organisation)
      @organisation = organisation

      replicate(patients.where(organisation: organisation))
    end

    def in_programme(programme)
      @programme = programme

      replicate(patients.in_programme(programme))
    end

    def from_cohort_imports
      replicate(patients.joins(:cohort_imports_patients))
    end

    def from_class_imports
      replicate(patients.joins(:class_imports_patients))
    end

    def in_sessions
      # Session
      #   .all
      #   .then { @organisation ? it.where(organisation: @organisation) : it }
      #   .then { @programme.present? ? it.has_programme(@programme) : it }
      #   .flat_map { it.patients.where(id: patients.pluck(:id)) }

      patients
        .joins(:sessions)
        .then do
          organisation ? it.where(sessions: { organisation: organisation }) : it
        end
        .then do
          if programme
            it.joins(sessions: :programmes).where(
              sessions: {
                programmes: programme
              }
            )
          else
            it
          end
        end
    end

    def ids
      patients.pluck(:id)
    end
  end

  attr_reader :organisation, :programme

  def initialize(organisation: nil, programme: nil)
    @organisation = organisation
    @programme = programme
  end

  def patients
    PatientCollection
      .new(Patient.all)
      .in_organisation(@organisation)
      .in_programme(@programme)
  end

  def render
    # Line to output unaccounted-for patients (this should be 0):
    # Unknown,Total Patients,#{patients_total - patient_ids_from_cohort_or_class_imports.count - patient_ids_from_consents.count}

    # ids_only_from_class_imports =
    #   (
    #     patients.from_class_imports.in_sessions.ids -
    #       patients.from_cohort_imports.in_sessions.ids
    #   )
    # ids_in_cohort_or_class_imports =
    #   patients.from_class_imports.in_sessions.ids &
    #     patients.from_cohort_imports.in_sessions.ids
    # ids_not_in_imports =
    #   (patients.where.not(id: ids_in_cohort_or_class_imports))

    # only_from_class_imports = patients.from_class_imports.not_in(patients.from_cohort_imports).in_sessions.ids.uniq.count

    # <<~DIAGRAM
    #   sankey-beta
    #   Cohort Upload,Total Patients,#{patients.from_cohort_imports.in_sessions.ids.uniq.count}
    #   Class Upload,Total Patients,#{ids_only_from_class_imports.uniq.count}
    #   Consent Forms,Total Patients,#{ids_not_in_imports.count}
    #   Total Patients,Consent Given,#{patient_ids_with_consent_response("given", @organisation, @programme).count}
    #   Total Patients,Consent Refused,#{patient_ids_with_consent_response("refused", @organisation, @programme).count}
    #   Total Patients,Consent Response Not Provided,#{patient_ids_with_consent_response("not_provided", @organisation, @programme).count}
    #   Total Patients,Without Consent Response,#{patient_ids_without_consent_response(@organisation, @programme).count}
    # DIAGRAM

    [
      [
        ["Cohort Upload", "Total Patients"],
        patient_ids_from_cohort_imports.count
      ],
      [
        ["Class Upload", "Total Patients"],
        patient_ids_from_class_not_cohort_imports.count
      ],
      [["Consent Forms", "Total Patients"], patient_ids_from_consents.count],
      [
        ["Total Patients", "Consent Given"],
        patient_ids_with_consent_response("given").count
      ],
      [
        ["Total Patients", "Consent Refused"],
        patient_ids_with_consent_response("refused").count
      ],
      [
        ["Total Patients", "Consent Response Not Provided"],
        patient_ids_with_consent_response("not_provided").count
      ],
      [
        ["Total Patients", "Without Consent Response"],
        patient_ids_without_consent_response.count
      ]
    ].map { |(from, to), count| "#{from},#{to},#{count}" }
      .prepend("sankey-beta")
      .join("\n") + "\n"

    # stats = {
    #   "Cohort Upload" => {
    #     "Total Patients" => patient_ids_from_cohort_imports.count
    #   },
    #   "Class Upload" => {
    #     "Total Patients" => patient_ids_from_class_not_cohort_imports.count
    #   },
    #   "Consent Forms" => {
    #     "Total Patients" => patient_ids_from_consents.count
    #   },
    #   "Total Patients" => {
    #     "Consent Given" => patient_ids_with_consent_response("given").count,
    #     "Consent Refused" => patient_ids_with_consent_response("refused").count,
    #     "Consent Response Not Provided" =>
    #       patient_ids_with_consent_response("not_provided").count,
    #     "Without Consent Response" => patient_ids_without_consent_response.count
    #   }
    # }

    # <<~DIAGRAM
    #   sankey-beta
    #   Cohort Upload,Total Patients,#{patient_ids_from_cohort_imports.count}
    #   Class Upload,Total Patients,#{patient_ids_from_class_not_cohort_imports.count}
    #   Consent Forms,Total Patients,#{patient_ids_from_consents.count}
    #   Total Patients,Consent Given,#{patient_ids_with_consent_response("given").count}
    #   Total Patients,Consent Refused,#{patient_ids_with_consent_response("refused").count}
    #   Total Patients,Consent Response Not Provided,#{patient_ids_with_consent_response("not_provided").count}
    #   Total Patients,Without Consent Response,#{patient_ids_without_consent_response.count}
    # DIAGRAM
  end

  def render_organisation
    diagram << <<~EOSANKEY
      sankey-beta
      Cohort Upload,Total Patients,#{patient_ids_from_cohort_imports(@organisation).count}
      Class Upload,Total Patients,#{patient_ids_from_class_not_cohort_imports(@organisation).count}
      Consent Forms,Total Patients,#{patient_ids_from_consents(@organisation).count}
    EOSANKEY

    diagram
  end

  def render_all_organisations
    diagram = "sankey-beta\n"

    Organisation.all.each do |org|
      ods = org.ods_code
      diagram << <<~EOSANKEY
        #{ods} Cohort Upload,#{ods} Total Patients,#{patient_ids_from_cohort_imports(org).count}
        #{ods} Class Upload,#{ods} Total Patients,#{patient_ids_from_class_not_cohort_imports(org).count}
        #{ods} Consent Forms,#{ods} Total Patients,#{patient_ids_from_consents(org).count}
      EOSANKEY
    end

    diagram
  end

  def patients_scoped
    Patient
      .all
      .then { organisation.present? ? it.where(organisation:) : it }
      .then { @programme.present? ? it.in_programmes([@programme]) : it }
  end

  # def patients_totals(org_id, prog_id)
  #   @patients_totals ||=
  #     Hash.new do |_hash, oid|
  #       Hash.new do |_hash, pid|
  #         patients = patients_scoped_to_org(oid)
  #         pid.present? ? patients.in_programme(pid) : patients
  #       end
  #     end
  #   @patients_totals[org_id][prog_id]
  # end

  def patients_totals(org_id, prog_id)
    @patients_totals ||=
      begin
        patients = patients_scoped_to_org(org_id)
        prog_id.present? ? patients.in_programme(prog_id) : patients
      end
  end

  def patient_ids_from_cohort_imports
    @patient_ids_from_cohort_imports ||=
      patients_scoped.then do
        it.joins(:cohort_imports_patients).distinct.pluck(:id)
      end
  end

  def patient_ids_from_class_imports
    @patient_ids_from_class_imports ||=
      patients_scoped.then do
        it.joins(:class_imports_patients).distinct.pluck(:id)
      end
  end

  def patient_ids_from_class_not_cohort_imports
    @patient_ids_from_class_not_cohort_imports ||=
      patient_ids_from_class_imports - patient_ids_from_cohort_imports
  end

  def patient_ids_from_cohort_or_class_imports
    @patient_ids_from_cohort_or_class_imports ||=
      patient_ids_from_cohort_imports | patient_ids_from_class_imports
  end

  def patient_ids_from_consents
    @patient_ids_from_consents ||=
      patients_scoped
        .where.not(id: patient_ids_from_cohort_or_class_imports)
        .ids
  end

  def patients_from_immunisation_imports_ids
    @patients_from_immunisation_imports_ids ||=
      Patient.joins(:immunisation_imports_patients).uniq.pluck(:id)
  end

  def consents_response_given_ids
    @consents_response_given_ids ||=
      Consent.where(response: "given").pluck(:patient_id)
  end

  def patient_ids_with_consent_response(response)
    # @patient_ids_with_consent_response ||=
    # Hash.new do |_hash, org|
    #   Hash.new do |_hash, prog|
    #     Hash.new do |_hash, resp|
    patients_scoped
      .joins(:consents)
      .where(consents: { programme: @programme, invalidated_at: nil })
      .in_batches
      .flat_map do |batch|
        batch
          .select { it.consents.max_by(&:created_at).response == response }
          .pluck(:id)
      end
    #     end
    #   end
    # end
    # @patient_ids_with_consent_response[organisation][programme][response]
  end

  def patient_ids_without_consent_response
    # @patient_ids_without_consent_response ||=
    # Hash.new do |_hash, org|
    #   Hash.new do |_hash, prog|
    patients_scoped
      .includes(:consents)
      .in_batches
      .flat_map do |batch|
        batch
          .select do
            it
              .consents
              .select { it.programme == @programme && it.invalidated_at.nil? }
              .none?
          end
          .pluck(:id)
      end
    #   end
    # end
    # @patient_ids_without_consent_response[organisation][programme]
  end

  def patient_ids_in_sessions(organisation = nil, programme = nil)
    @patient_ids_in_sessions ||=
      Hash.new do |_hash, org|
        Hash.new do |_hash, prog|
          Session
            .where(organisation: org)
            .then { programme.present? ? it.has_programme(prog) : it }
            .flat_map { it.patients.ids }
            .uniq
        end
      end
    @patient_ids_in_sessions[organisation][programme]
  end

  def hpv
    @hpv ||= Programme.find_by(type: "hpv")
  end

  def patient_ids_from_cohort_imports_in_sessions(
    organisation = nil,
    programme = nil
  )
    organisation ||= @organisation
    programme ||= @programme

    patient_ids_from_cohort_imports(organisation, programme) &
      patient_ids_in_sessions(organisation, programme)
  end

  def patient_ids_from_class_not_cohort_imports_in_sessions(
    organisation,
    programme
  )
    patient_ids_from_class_not_cohort_imports(organisation, programme) &
      patient_ids_in_sessions(organisation, programme)
  end

  def patient_ids_from_consents_in_sessions(organisation = nil, programme = nil)
    organisation ||= @organisation
    programme ||= @programme

    patient_ids_from_consents(organisation, programme) &
      patient_ids_in_sessions(organisation, programme)
  end
end
