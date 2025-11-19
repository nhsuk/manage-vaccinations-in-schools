# frozen_string_literal: true

class PatientImport < ApplicationRecord
  PDS_MATCH_THRESHOLD = 0.7
  CHANGESET_THRESHOLD = 10

  self.abstract_class = true

  has_many :patient_changesets

  scope :status_for_uploaded_files,
        -> do
          where(
            status: %i[
              pending_import
              rows_are_invalid
              low_pds_match_rate
              changesets_are_invalid
              in_review
              calculating_re_review
              in_re_review
              committing
              cancelled
            ]
          )
        end
  scope :status_for_imported_records,
        -> { where(status: %i[processed partially_processed]) }

  def count_column(patient, parents, parent_relationships)
    if patient.new_record? || parents.any?(&:new_record?) ||
         parent_relationships.any?(&:new_record?)
      :new_record_count
    elsif patient.changed? || parents.any?(&:changed?) ||
          parent_relationships.any?(&:changed?)
      :changed_record_count
    else
      :exact_duplicate_record_count
    end
  end

  def validate_pds_match_rate!
    return if valid_pds_match_rate? || changesets.count < CHANGESET_THRESHOLD

    update!(status: :low_pds_match_rate)
    changesets.update_all(status: :import_invalid)
  end

  def pds_match_rate
    return 0 if changesets.with_pds_match.count.zero?

    matched = changesets.with_pds_match.count.to_f
    attempted = changesets.with_pds_search_attempted.count

    (matched / attempted * 100).round(2)
  end

  def validate_changeset_uniqueness!
    row_errors = {}

    nhs_duplicates =
      changesets
        .group_by(&:nhs_number)
        .select { |nhs, cs| nhs.present? && cs.size > 1 }

    nhs_duplicates.each do |nhs_number, changesets|
      changesets.each do |cs|
        other_rows_text = generate_other_rows_text(cs, changesets)
        row_errors["Row #{cs.row_number + 2}"] ||= [[]]
        row_errors["Row #{cs.row_number + 2}"][
          0
        ] << "The details on this row match #{other_rows_text}. " \
          "Mavis has found the NHS number #{nhs_number}."
      end
    end

    patient_duplicates =
      changesets
        .group_by(&:patient_id)
        .select { |pid, cs| pid.present? && cs.size > 1 }

    patient_duplicates.each_value do |changesets|
      changesets.each do |cs|
        other_rows_text = generate_other_rows_text(cs, changesets)
        row_errors["Row #{cs.row_number + 2}"] ||= [[]]
        row_errors["Row #{cs.row_number + 2}"][
          0
        ] << "The record on this row appears to be a duplicate of #{other_rows_text}."
      end
    end

    if row_errors.any?
      update!(status: :changesets_are_invalid)
      update!(serialized_errors: row_errors)
      changesets.update_all(status: :import_invalid)
    end
  end

  def commit_changesets(changesets)
    changesets_ids = changesets.ids

    changesets.update_all(status: :committing)
    changesets_ids.each_slice(100) do |batch_ids|
      CommitPatientChangesetsJob.perform_async(batch_ids)
    end
  end

  private

  def check_rows_are_unique
    rows
      .map(&:nhs_number_value)
      .tally
      .each do |nhs_number, count|
        next if nhs_number.nil? || count <= 1

        rows
          .select { _1.nhs_number_value == nhs_number }
          .each do |row|
            row.errors.add(
              :base,
              "The same NHS number appears multiple times in this file."
            )
          end
      end
  end

  def valid_pds_match_rate?
    pds_match_rate / 100 >= PDS_MATCH_THRESHOLD
  end

  def generate_other_rows_text(current_row, duplicate_rows, count = 5)
    current_row_index =
      duplicate_rows.index { it.row_number == current_row.row_number }
    start_row = [current_row_index - count, 0].max
    other_rows = duplicate_rows[start_row, count + 1] - [current_row]
    other_row_numbers = other_rows.map { it.row_number + 2 }

    if other_row_numbers.size == 1
      "row #{other_row_numbers.first}"
    else
      "rows #{other_row_numbers[0..-2].join(", ")} and #{other_row_numbers[-1]}"
    end
  end
end
