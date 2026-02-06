# frozen_string_literal: true

class SchoolTeamContactForm
  include RequestSessionPersistable
  include WizardStepConcern

  attribute :school_id, :integer

  def initialize(request_session:, **attributes)
    super(request_session:, **attributes)
  end

  def wizard_steps
    %i[school contact_details]
  end

  on_wizard_step :school, exact: true do
    validates :school_id, presence: { message: "Select a school" }
  end

  def school
    return nil if school_id.blank?

    @school ||=
      Location
        .school
        .find_by(id: school_id)
  end

  def request_session_key
    "school_team_contact"
  end
end
