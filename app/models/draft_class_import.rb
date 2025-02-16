# frozen_string_literal: true

class DraftClassImport
  include RequestSessionPersistable
  include WizardStepConcern

  def self.request_session_key
    "class_import"
  end

  attribute :session_id, :integer

  on_wizard_step :session, exact: true do
    validates :session_id, presence: true
  end

  def wizard_steps
    %i[session]
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
