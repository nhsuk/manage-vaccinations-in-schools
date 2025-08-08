# frozen_string_literal: true

class SchoolMoveExport
  include RequestSessionPersistable
  include WizardStepConcern

  attribute :date_from, :date
  attribute :date_to, :date

  def initialize(current_user:, **attributes)
    @current_user = current_user
    super(**attributes)
  end

  def wizard_steps
    %i[dates confirm]
  end

  delegate :csv_data, :row_count, to: :exporter

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

  def exporter
    @exporter ||=
      Reports::SchoolMovesExporter.new(
        team: @current_user.selected_team,
        start_date: date_from,
        end_date: date_to
      )
  end

  def request_session_key = "school_move_export"
end
