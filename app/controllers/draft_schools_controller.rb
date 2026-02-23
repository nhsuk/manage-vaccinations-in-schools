# frozen_string_literal: true

class DraftSchoolsController < ApplicationController
  before_action :set_draft_school
  before_action :set_school
  before_action :redirect_if_session_cleared, only: %i[show update]

  include WizardControllerConcern

  before_action :set_school_options, if: -> { current_step == :school }
  before_action :set_address, if: -> { current_step == :details }
  before_action :set_site_letter, if: -> { current_step == :confirm }

  skip_after_action :verify_policy_scoped

  def show
    authorize Location, :new?, policy_class: SchoolPolicy

    render_wizard
  end

  def update
    authorize Location, :create?, policy_class: SchoolPolicy

    case current_step
    when :school
      handle_school
    when :confirm
      handle_confirm
    else
      @draft_school.assign_attributes(update_params)
    end

    reload_steps

    render_wizard @draft_school
  end

  private

  def set_draft_school
    @draft_school = DraftSchool.new(request_session: session, current_user:)
  end

  def set_school
    @school = Location.new
  end

  def set_site_letter
    @site_letter = next_site_letter(@draft_school.urn)
  end

  def set_school_options
    @school_options =
      policy_scope(Location)
        .school
        .joins(:team_locations)
        .where(team_locations: { academic_year: AcademicYear.pending })
        .distinct
        .order(:urn, :name)
  end

  def set_steps
    self.steps = @draft_school.wizard_steps
  end

  def set_address
    parent_school = @draft_school.parent_school

    @draft_school.address_line_1 ||= parent_school&.address_line_1
    @draft_school.address_line_2 ||= parent_school&.address_line_2
    @draft_school.address_town ||= parent_school&.address_town
    @draft_school.address_postcode ||= parent_school&.address_postcode
  end

  def handle_school
    @draft_school.clear!
    @draft_school.assign_attributes(update_params)
  end

  def handle_confirm
    return unless @draft_school.save

    @draft_school.assign_attributes(update_params)

    parent_school = @draft_school.parent_school
    @school = parent_school.dup

    @school.assign_attributes(
      urn: @draft_school.urn,
      site: next_site_letter(@draft_school.urn),
      name: @draft_school.name,
      address_line_1: @draft_school.address_line_1,
      address_line_2: @draft_school.address_line_2,
      address_town: @draft_school.address_town,
      address_postcode: @draft_school.address_postcode
    )

    ActiveRecord::Base.transaction do
      @school.save!
      academic_year = AcademicYear.pending

      parent_school
        .teams_for_academic_year(academic_year)
        .each do |team|
          @school.attach_to_team!(team, academic_year:)
          @school.import_year_groups_from_gias!(academic_year:)
          @school.import_default_programme_year_groups!(
            team.programmes,
            academic_year:
          )
        end

      parent_school.update!(site: "A") if parent_school.site.nil?
    end

    flash[:success] = "#{@school.name} has been added to your team."

    @draft_school.clear!
  end

  def finish_wizard_path
    schools_team_path
  end

  def update_params
    permitted_attributes = {
      school: [:urn],
      details: %i[
        name
        address_line_1
        address_line_2
        address_town
        address_postcode
      ],
      confirm: []
    }.fetch(current_step)

    params
      .fetch(:draft_school, {})
      .permit(permitted_attributes)
      .merge(wizard_step: current_step)
  end

  def next_site_letter(urn)
    existing_sites =
      policy_scope(Location).where(urn:).pluck(:site).compact.sort
    return "B" if existing_sites.empty?

    existing_sites.max_by { [it.length, it] }.next
  end

  def redirect_if_session_cleared
    return if params[:id] == "wicked_finish"
    return if params[:id] == "school" # Allow school selection step even with blank URN
    return if session[:draft_school].present? && @draft_school.urn.present?

    redirect_to schools_team_path if @draft_school.urn.blank?
  end
end
