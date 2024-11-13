# frozen_string_literal: true

class VaccinationReport
  include RequestSessionPersistable
  include WizardStepConcern

  FILE_FORMATS = %w[careplus mavis].freeze

  def self.request_session_key
    "vaccination_report"
  end

  attribute :date_from, :datetime
  attribute :date_to, :integer
  attribute :file_format, :string
  attribute :programme_id, :integer

  def wizard_steps
    %i[dates file_format]
  end

  on_wizard_step :file_format, exact: true do
    validates :file_format, inclusion: { in: FILE_FORMATS }
  end

  def programme
    ProgrammePolicy::Scope
      .new(@current_user, Programme)
      .resolve
      .find_by(id: programme_id)
  end

  def programme=(value)
    self.programme_id = value.id
  end

  def csv_data
    case file_format
    when "careplus"
      Reports::CareplusExporter.call(
        programme:,
        start_date: date_from,
        end_date: date_to
      )
    when "mavis"
      ""
    end
  end

  def csv_filename
    return nil if invalid?

    from_str = date_from&.to_fs(:long) || "earliest"
    to_str = date_to&.to_fs(:long) || "latest"

    "#{programme.name} - #{file_format} - #{from_str} - #{to_str}.csv"
  end

  private

  def reset_unused_fields
  end
end
