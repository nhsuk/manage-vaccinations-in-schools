# frozen_string_literal: true

class DraftClassImport
  include RequestSessionPersistable
  include WizardStepConcern

  def self.request_session_key
    "class_import"
  end

  attribute :session_id, :integer
  attribute :year_groups, array: true, default: []

  def wizard_steps
    %i[session year_groups]
  end

  on_wizard_step :session, exact: true do
    validates :session_id, presence: true
  end

  on_wizard_step :year_groups, exact: true do
    validates :year_groups, presence: true
  end

  def session
    SessionPolicy::Scope
      .new(@current_user, Session)
      .resolve
      .find_by(id: session_id)
  end

  def session=(value)
    self.session_id = value.id
  end

  private

  def reset_unused_fields
  end
end
