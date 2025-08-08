# frozen_string_literal: true

class VaccinationReport
  include RequestSessionPersistable
  include WizardStepConcern

  def self.file_formats(programme)
    %w[careplus mavis].tap do
      it << "systm_one" if programme.hpv? || programme.flu?
    end
  end

  attribute :date_from, :date
  attribute :date_to, :date
  attribute :file_format, :string
  attribute :programme_id, :integer
  attribute :academic_year, :integer

  def initialize(current_user:, **attributes)
    @current_user = current_user
    super(**attributes)
  end

  def wizard_steps
    %i[dates file_format]
  end

  on_wizard_step :file_format, exact: true do
    validates :file_format,
              inclusion: {
                in: -> { VaccinationReport.file_formats(it.programme) }
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
      team: @current_user.selected_team,
      programme:,
      academic_year:,
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

  def request_session_key = "vaccination_report"
end
