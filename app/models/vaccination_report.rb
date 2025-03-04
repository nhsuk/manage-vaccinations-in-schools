# frozen_string_literal: true

class VaccinationReport
  include RequestSessionPersistable
  include WizardStepConcern

  def self.request_session_key
    "vaccination_report"
  end

  def self.file_formats
    %w[careplus mavis].tap do
      it << "systm_one" if Flipper.enabled?(:systm_one_exporter)
    end
  end

  attribute :date_from, :date
  attribute :date_to, :date
  attribute :file_format, :string
  attribute :programme_id, :integer

  def wizard_steps
    %i[dates file_format]
  end

  on_wizard_step :file_format, exact: true do
    validates :file_format,
              inclusion: {
                in: -> { VaccinationReport.file_formats }
              }
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
    exporter_class.call(
      organisation: @current_user.selected_organisation,
      programme:,
      start_date: date_from,
      end_date: date_to
    )
  end

  def csv_filename
    return nil if invalid?

    from_str = date_from&.to_fs(:long) || "earliest"
    to_str = date_to&.to_fs(:long) || "latest"

    "#{programme.name} - #{file_format} - #{from_str} - #{to_str}.csv"
  end

  private

  def exporter_class
    {
      careplus: Reports::CareplusExporter,
      mavis: Reports::ProgrammeVaccinationsExporter,
      systm_one: Reports::SystmOneExporter
    }.fetch(file_format.to_sym)
  end

  def reset_unused_fields
  end
end
