# frozen_string_literal: true

class DraftSchool
  include RequestSessionPersistable
  include WizardStepConcern

  attribute :urn, :string
  attribute :confirm_school, :string

  attribute :wizard_step, :string

  def initialize(request_session:, current_user:, current_team:, **attributes)
    super(request_session:, **attributes)
    @current_user = current_user
    @current_team = current_team
  end

  def wizard_steps
    %i[urn confirm]
  end

  on_wizard_step :urn, exact: true do
    validates :urn, presence: true
    validate :school_exists_and_available
  end

  on_wizard_step :confirm, exact: true do
    validates :confirm_school,
              presence: {
                message: "Select yes if this is the correct school"
              }
  end

  def school
    return nil if urn.blank?

    @school ||= Location.school.find_by_urn_and_site(urn.strip)
  end

  def schools_to_add
    return [] if school.nil?

    all_sites = Location.school.where(urn: school.urn).to_a

    if all_sites.count > 1
      all_sites.select { |it| it.site.present? }
    else
      all_sites
    end
  end

  def request_session_key = "draft_school"

  def address_parts
    [
      school.address_line_1,
      school.address_line_2,
      school.address_town,
      school.address_postcode
    ].compact_blank
  end

  private

  attr_reader :current_user, :current_team

  def school_exists_and_available
    return if urn.blank?

    if school.nil?
      errors.add(:urn, "No school found with this URN")
      return
    end

    if school.closed?
      errors.add(:urn, "This school is closed and cannot be assigned")
      return
    end

    if Location
         .where(id: schools_to_add.map(&:id))
         .joins(:team_locations)
         .where(
           team_locations: {
             team: current_team,
             academic_year: AcademicYear.pending
           }
         )
         .exists?
      errors.add(
        :urn,
        "This school or its sites are already assigned to your team"
      )
      return
    end

    sites_with_teams =
      Location
        .where(id: schools_to_add.map(&:id))
        .joins(:team_locations)
        .where(team_locations: { academic_year: AcademicYear.pending })
        .where.not(team_locations: { team: current_team })

    if sites_with_teams.exists?
      errors.add(:urn, "This school is already assigned to a different team")
    end
  end
end
