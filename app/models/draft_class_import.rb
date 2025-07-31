# frozen_string_literal: true

class DraftClassImport
  include RequestSessionPersistable
  include WizardStepConcern

  attribute :location_id, :integer
  attribute :year_groups, array: true, default: []

  def initialize(current_user:, **attributes)
    @current_user = current_user
    super(**attributes)
  end

  def wizard_steps
    %i[location year_groups]
  end

  on_wizard_step :location, exact: true do
    validates :location_id, presence: true
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

  private

  def request_session_key = "class_import"

  def reset_unused_fields
  end
end
