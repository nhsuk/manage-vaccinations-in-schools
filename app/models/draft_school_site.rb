# frozen_string_literal: true

class DraftSchoolSite
  include RequestSessionPersistable
  include WizardStepConcern

  attribute :urn, :string
  attribute :name, :string
  attribute :address_line_1, :string
  attribute :address_line_2, :string
  attribute :address_town, :string
  attribute :address_postcode, :string

  attribute :wizard_step, :string

  def initialize(request_session:, current_user:, **attributes)
    @current_user = current_user
    super(request_session:, **attributes)
  end

  def wizard_steps
    %i[school details confirm]
  end

  on_wizard_step :school, exact: true do
    validates :urn, presence: true
  end

  on_wizard_step :details, exact: true do
    validates :name, presence: true
    validates :name,
              exclusion: {
                in: ->(record) { record.existing_names },
                message:
                  "This site name is already in use. Enter a different name."
              }
    validates :address_line_1, presence: true
    validates :address_town, presence: true
    validates :address_postcode, postcode: true
  end

  def parent_school
    return nil if urn.nil?

    @parent_school ||=
      LocationPolicy::Scope.new(@current_user, Location).resolve.find_by(urn:)
  end

  def existing_names
    return [] if urn.blank?

    Location.where(urn:).pluck(:name)
  end

  def request_session_key = "draft_school"

  def address_parts
    [
      address_line_1,
      address_line_2,
      address_town,
      address_postcode
    ].compact_blank
  end
end
