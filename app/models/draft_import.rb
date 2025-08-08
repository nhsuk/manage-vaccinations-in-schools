# frozen_string_literal: true

class DraftImport
  include RequestSessionPersistable
  include WizardStepConcern

  attribute :academic_year, :integer
  attribute :location_id, :integer
  attribute :type, :string
  attribute :year_groups, array: true, default: []

  def initialize(current_user:, **attributes)
    @current_user = current_user
    super(**attributes)
  end

  def wizard_steps
    steps = %i[type]

    steps << :location if is_class_import?
    steps << :academic_year if ask_academic_year?
    steps << :year_groups if is_class_import?

    steps
  end

  def year_groups=(value)
    super(value&.compact_blank || [])
  end

  on_wizard_step :academic_year, exact: true do
    validates :academic_year, inclusion: { in: :academic_year_values }
  end

  on_wizard_step :location, exact: true do
    validates :location_id, presence: true
  end

  on_wizard_step :type, exact: true do
    validates :type, inclusion: %w[class cohort immunisation]
  end

  on_wizard_step :year_groups, exact: true do
    validates :year_groups, presence: true
  end

  def location
    return nil if location_id.nil?

    LocationPolicy::Scope.new(@current_user, Location).resolve.find(location_id)
  end

  def location=(value)
    self.location_id = value.id
  end

  def is_class_import? = type == "class"

  def is_cohort_import? = type == "cohort"

  private

  def ask_academic_year?
    (is_class_import? || is_cohort_import?) &&
      AcademicYear.pending != AcademicYear.current &&
      Flipper.enabled?(:import_choose_academic_year)
  end

  def academic_year_values = [AcademicYear.current, AcademicYear.pending].uniq

  def request_session_key = "import"

  def reset_unused_attributes
    self.academic_year = AcademicYear.pending unless ask_academic_year?

    unless is_class_import?
      self.location_id = nil
      self.year_groups = []
    end
  end
end
