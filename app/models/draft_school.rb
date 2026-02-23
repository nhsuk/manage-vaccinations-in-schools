# frozen_string_literal: true

class DraftSchool
  include RequestSessionPersistable
  include EditableWrapper
  include WizardStepConcern

  attribute :parent_urn_and_site, :string
  attribute :name, :string
  attribute :address_line_1, :string
  attribute :address_line_2, :string
  attribute :address_town, :string
  attribute :address_postcode, :string

  def initialize(request_session:, current_user:, **attributes)
    @current_user = current_user
    super(request_session:, **attributes)
  end

  def name=(value)
    super(ApostropheNormaliser.call(value.presence&.normalise_whitespace))
  end

  def address_line_1=(value)
    super(ApostropheNormaliser.call(value.presence&.normalise_whitespace))
  end

  def address_line_2=(value)
    super(ApostropheNormaliser.call(value.presence&.normalise_whitespace))
  end

  def address_town=(value)
    super(ApostropheNormaliser.call(value.presence&.normalise_whitespace))
  end

  def wizard_steps
    %i[school details confirm]
  end

  on_wizard_step :school, exact: true do
    validates :parent_urn_and_site, presence: true
  end

  on_wizard_step :details, exact: true do
    validates :name, presence: true
    validates :name, name: { school_name: true }
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
    return nil if parent_urn_and_site.blank?

    @parent_school ||=
      LocationPolicy::Scope
        .new(@current_user, Location)
        .resolve
        .find_by_urn_and_site(parent_urn_and_site)
  end

  def urn
    parent_school&.urn
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

  def urn_and_site
    return nil if urn.blank?

    "#{urn}#{next_site_letter}"
  end

  def next_site_letter
    return nil if urn.blank?

    existing_sites = Location.where(urn:).pluck(:site).compact.sort
    return "B" if existing_sites.empty?

    existing_sites.max_by { [it.length, it] }.next
  end

  def source_location
    parent_school
  end

  def year_groups
    source_location&.year_groups || []
  end

  def programmes
    source_location&.programmes || []
  end

  def human_enum_name(attr)
    source_location&.human_enum_name(attr)
  end
end
