#!/usr/bin/env ruby

class PipelineStats
  attr_reader :organisations, :programmes

  def initialize(organisations: nil, programmes: nil)
    @organisations =
      if programmes.nil?
        organisations
      else
        (organisations.nil? ? Organisation.all : organisations).select do |org|
          org.programmes.any? { it.in? programmes }
        end
      end
    @programmes = programmes
  end

  def render
    # Line to output unaccounted-for patients (this should be 0):
    # Unknown,Cohort Patients,#{patients_total - patient_ids_from_cohort_or_class_imports.count - patient_ids_from_consents.count}

    [
      [
        ["Cohort Upload", "Uploaded Patients"],
        patient_ids_from_cohort_imports.count
      ],
      [
        ["Class Upload", "Uploaded Patients"],
        patient_ids_from_class_not_cohort_imports.count
      ],
      [
        ["Uploaded Patients", "Consent Requests Sent"],
        consent_requests_sent_count
      ],
      [["Consent Requests Sent", "Consent Responses"], consent_responses_count],
      [
        ["Consent Responses", "Consent Given"],
        patient_ids_with_consent_response("given").uniq.count
      ],
      [
        ["Consent Responses", "Consent Refused"],
        patient_ids_with_consent_response("refused").uniq.count
      ],
      [
        ["Consent Responses", "Without Consent Response"],
        patient_ids_without_consent_response.count
      ]
    ].map { |(from, to), count| "#{from},#{to},#{count}" }
      .prepend("sankey-beta")
      .join("\n") + "\n"
  end

  # def render_organisation
  #   diagram << <<~EOSANKEY
  #     sankey-beta
  #     Cohort Upload,Cohort Patients,#{patient_ids_from_cohort_imports(@organisation).count}
  #     Class Upload,Cohort Patients,#{patient_ids_from_class_not_cohort_imports(@organisation).count}
  #     Consent Forms,Cohort Patients,#{patient_ids_from_consents(@organisation).count}
  #   EOSANKEY

  #   diagram
  # end

  # def render_all_organisations
  #   diagram = "sankey-beta\n"

  #   Organisation.all.each do |org|
  #     ods = org.ods_code
  #     diagram << <<~EOSANKEY
  #       #{ods} Cohort Upload,#{ods} Cohort Patients,#{patient_ids_from_cohort_imports(org).count}
  #       #{ods} Class Upload,#{ods} Cohort Patients,#{patient_ids_from_class_not_cohort_imports(org).count}
  #       #{ods} Consent Forms,#{ods} Cohort Patients,#{patient_ids_from_consents(org).count}
  #     EOSANKEY
  #   end

  #   diagram
  # end

  def patients_scoped
    Patient
      .readonly
      .all
      .then { organisations.nil? ? it : it.where(organisation: organisations) }
      .then { programmes.nil? ? it : it.in_programmes(programmes) }
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
      patients_scoped
        .joins(:cohort_imports)
        .then do
          if organisations.nil?
            it
          else
            it.where(cohort_imports: { organisation: organisations })
          end
        end
        .distinct
        .pluck(:id)
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
      Patient.readonly.joins(:immunisation_imports_patients).uniq.pluck(:id)
  end

  def consent_requests_sent_count
    ConsentNotification
      .readonly
      .includes(:programmes)
      .select("DISTINCT ON (patient_id) *")
      .sum do
        if programmes.nil?
          it.programmes.count
        else
          groups = ProgrammeGrouper.call(it.programmes)
          programmes.count { |prog| groups.any? { |_, group| prog.in?(group) } }
        end
      end
  end

  def consent_responses_count
    Consent
      .readonly
      .not_invalidated
      .not_response_not_provided
      .where(recorded_by_user_id: nil)
      .pluck(:patient_id)
      .uniq
      .count
  end

  def consents_response_given_ids
    @consents_response_given_ids ||=
      Consent.readonly.where(response: "given").pluck(:patient_id)
  end

  def patient_ids_with_consent_response(response)
    where_clause = { consents: { invalidated_at: nil } }
    unless programmes.nil?
      where_clause[:consents].merge({ programme: programmes })
    end

    patients_scoped
      .joins(:consents)
      .where(where_clause)
      .in_batches
      .flat_map do |batch|
        batch
          .select { it.consents.max_by(&:created_at).response == response }
          .pluck(:id)
      end
  end

  def patient_ids_without_consent_response
    patients_scoped
      .includes(:consents)
      .in_batches
      .flat_map do |batch|
        batch
          .select do
            it
              .consents
              .select do
                it.invalidated_at.nil? &&
                  (programmes.nil? || it.programme.in?(programmes))
              end
              .none?
          end
          .pluck(:id)
      end
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
