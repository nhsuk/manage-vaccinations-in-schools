# frozen_string_literal: true

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
    # patients_total - patient_ids_from_cohort_or_class_imports.count - patient_ids_from_consents.count

    [ # rubocop:disable Style/StringConcatenation
      [
        ["Cohort Upload", "Uploaded Patients"],
        patients_from_cohort_imports.count
      ],
      [
        ["Class Upload", "Uploaded Patients"],
        patient_ids_from_class_not_cohort_imports.count
      ],
      [
        ["Uploaded Patients", "Consent Requests Sent"],
        count_consent_requests_sent
      ],
      [["Consent Requests Sent", "Consent Responses"], count_consent_responses],
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

  def patients_scoped
    Patient
      .readonly
      .all
      .then { organisations.nil? ? it : it.where(organisation: organisations) }
      .then { programmes.nil? ? it : it.in_programmes(programmes) }
  end

  def patients_totals(org_id, prog_id)
    @patients_totals ||=
      begin
        patients = patients_scoped_to_org(org_id)
        prog_id.present? ? patients.in_programme(prog_id) : patients
      end
  end

  def patients_from_cohort_imports
    @patients_from_cohort_imports ||=
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
  end

  def patients_from_class_imports
    @patients_from_class_imports ||=
      patients_scoped.joins(:class_imports_patients).distinct
  end

  def patient_ids_from_class_not_cohort_imports
    @patient_ids_from_class_not_cohort_imports ||=
      patients_from_class_imports.ids - patients_from_cohort_imports.ids
  end

  def patient_ids_from_cohort_or_class_imports
    @patient_ids_from_cohort_or_class_imports ||=
      patients_from_cohort_imports.ids | patients_from_class_imports.ids
  end

  def patient_ids_from_consents
    @patient_ids_from_consents ||=
      patients_scoped
        .where.not(id: patient_ids_from_cohort_or_class_imports)
        .ids
  end

  def patients_from_immunisation_imports
    @patients_from_immunisation_imports ||=
      Patient.readonly.joins(:immunisation_imports_patients).distinct
  end

  def count_consent_requests_sent
    @count_consent_requests_sent ||=
      begin
        where = {}
        includes = []

        unless programmes.nil?
          where[:programmes] = programmes
          includes << :programmes
        end

        unless organisations.nil?
          where[:session] = { organisation: organisations }
          includes << :session
        end

        ConsentNotification
          .readonly
          .then { includes.any? ? it.includes(*includes) : it }
          .then { where.any? ? it.where(**where) : it }
          .distinct
          .count(:patient_id)
      end
  end

  def count_consent_responses
    @count_consent_responses ||=
      Consent
        .readonly
        .not_invalidated
        .not_response_not_provided
        .then do
          where = { recorded_by_user_id: nil }
          where[:programme] = programmes unless programmes.nil?
          where[:organisation] = organisations unless organisations.nil?

          it.where(**where)
        end
        .distinct
        .count(:patient_id)
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
end
