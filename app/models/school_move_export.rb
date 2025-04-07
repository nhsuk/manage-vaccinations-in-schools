# frozen_string_literal: true

class SchoolMoveExport
  include RequestSessionPersistable
  include WizardStepConcern

  attribute :date_from, :date
  attribute :date_to, :date

  def wizard_steps
    %i[dates confirm].freeze
  end

  delegate :count, to: :school_moves

  def self.request_session_key
    "school_move_export"
  end

  def csv_data
    Reports::CSVSchoolMoves.call(school_moves)
  end

  def csv_filename
    name_parts = ["school_moves_export"]
    name_parts << date_from.to_fs(:govuk) if date_from.present?
    name_parts << "to" if date_from.present? && date_to.present?
    name_parts << date_to.to_fs(:govuk) if date_to.present?

    "#{name_parts.join("_")}.csv"
  end

  def date_from_formatted
    if date_from.present?
      date_from.strftime("%d %B %Y")
    else
      "Earliest recorded vaccination"
    end
  end

  def date_to_formatted
    if date_to.present?
      date_to.strftime("%d %B %Y")
    else
      "Latest recorded vaccination"
    end
  end

  private

  def school_moves
    scope =
      SchoolMoveLogEntry.where(
        patient: @current_user.selected_organisation.patients
      )

    if date_from.present?
      scope =
        scope.where(
          "school_move_log_entries.created_at >= ?",
          date_from.beginning_of_day
        )
    end

    if date_to.present?
      scope =
        scope.where(
          "school_move_log_entries.created_at <= ?",
          date_to.end_of_day
        )
    end

    scope
  end

  def reset_unused_fields
  end
end
