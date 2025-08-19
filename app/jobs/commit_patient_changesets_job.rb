# frozen_string_literal: true

class CommitPatientChangesetsJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  # Only permit one job to run per import.
  good_job_control_concurrency_with perform_limit: 1,
                                    key: -> { arguments.first.id }

  def perform(import)
    counts = import.class.const_get(:COUNT_COLUMNS).index_with(0)

    ActiveRecord::Base.transaction do
      import
        .changesets
        .includes(:school)
        .find_in_batches(batch_size: 100) do |changesets|
          import_patients_and_parents(changesets, import)

          import_school_moves(changesets, import)

          increment_column_counts!(import, counts, changesets)
        end

      import.postprocess_rows!

      import.update_columns(
        processed_at: Time.zone.now,
        status: :processed,
        **counts
      )
    end
  end

  def import_patients_and_parents(changesets, import)
    patients = changesets.map(&:patient)
    parents = changesets.flat_map(&:parents).uniq
    relationships =
      changesets
        .flat_map(&:parent_relationships)
        .uniq { [_1.parent, _1.patient] }

    deduplicate_patients!(patients, relationships)
    Patient.import(patients.to_a, on_duplicate_key_update: :all)
    link_records_to_import(import, Patient, patients)

    Parent.import(parents.to_a, on_duplicate_key_update: :all)
    link_records_to_import(import, Parent, parents)

    ParentRelationship.import(
      relationships.to_a,
      on_duplicate_key_update: {
        conflict_target: %i[parent_id patient_id],
        columns: %i[type other_name]
      }
    )
    link_records_to_import(import, ParentRelationship, relationships)
  end

  def deduplicate_patients!(patients, relationships)
    @patients_by_nhs_number ||= {}

    patients.reject! do |patient|
      next false if patient.nhs_number.blank?

      existing_patient = @patients_by_nhs_number[patient.nhs_number]
      if patient.persisted? || existing_patient.nil?
        @patients_by_nhs_number[patient.nhs_number] = patient
        next false
      else
        relationships
          .select { _1.patient == patient }
          .each { _1.patient = existing_patient }
        next true
      end
    end
  end

  def import_school_moves(changesets, import)
    school_moves = changesets.map(&:school_move).compact
    auto_confirmable_school_moves, importable_school_moves =
      school_moves.partition { has_auto_confirmable_school_move?(it, import) }

    auto_confirmable_school_moves.each do |school_move|
      # if the same patient appears multiple times in the file,
      # the duplicates won't be persisted, so we can skip those
      school_move.confirm! if school_move.patient.persisted?
    end

    SchoolMove.import(
      importable_school_moves.to_a,
      on_duplicate_key_ignore: :all
    )
  end

  def link_records_to_import(import_source, record_class, records)
    source_type = import_source.class.name
    record_type = record_class.name

    join_table_class = "#{source_type.pluralize}#{record_type}".constantize
    join_table_class.import(
      ["#{source_type.underscore}_id", "#{record_type.underscore}_id"],
      records.map { [import_source.id, it.id] },
      on_duplicate_key_ignore: true
    )
  end

  def increment_column_counts!(import, counts, changesets)
    changesets.each do |changeset|
      count_column_to_increment =
        import.count_column(
          changeset.patient,
          changeset.parents,
          changeset.parent_relationships
        )
      counts[count_column_to_increment] += 1
    end
  end

  def has_auto_confirmable_school_move?(school_move, import)
    (school_move.patient.school.nil? && !school_move.patient.home_educated) ||
      school_move.patient.not_in_team?(
        team: import.team,
        academic_year: import.academic_year
      ) || school_move.patient.archived?(team: import.team)
  end
end
