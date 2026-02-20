# frozen_string_literal: true

class DraftSchoolsController < ApplicationController
  before_action :set_draft_school
  before_action :set_team

  include WizardControllerConcern

  skip_after_action :verify_policy_scoped

  def show
    authorize Location, :new?, policy_class: SchoolPolicy

    render_wizard
  end

  def update
    authorize Location, :create?, policy_class: SchoolPolicy

    case current_step
    when :urn
      handle_urn
    when :confirm
      handle_confirm
    end

    reload_steps

    render_wizard @draft_school
  end

  private

  def set_draft_school
    @draft_school =
      DraftSchool.new(request_session: session, current_user:, current_team:)
  end

  def set_team
    @team = current_team
  end

  def set_steps
    self.steps = @draft_school.wizard_steps
  end

  def handle_urn
    @draft_school.clear!
    @draft_school.assign_attributes(update_params)
    @draft_school.wizard_step = current_step
  end

  def handle_confirm
    @draft_school.assign_attributes(update_params)

    if update_params[:confirm_school] == "no"
      jump_to(:urn)
      return
    end

    return unless @draft_school.save

    schools = @draft_school.schools_to_add
    academic_year = AcademicYear.pending

    ActiveRecord::Base.transaction do
      schools.each do |school|
        school.attach_to_team!(@team, academic_year:)
        school.import_year_groups_from_gias!(academic_year:)
        school.import_default_programme_year_groups!(
          @team.programmes,
          academic_year:
        )
      end
    end

    if schools.count > 1
      flash[
        :success
      ] = "#{schools.first.name} and #{schools.count - 1} #{"site".pluralize(schools.count - 1)} have been added to your team."
    else
      flash[:success] = "#{schools.first.name} has been added to your team."
    end

    @draft_school.clear!
  end

  def finish_wizard_path
    schools_team_path
  end

  def update_params
    permitted_attributes = { urn: [:urn], confirm: [:confirm_school] }.fetch(
      current_step
    )

    params
      .fetch(:draft_school, {})
      .permit(permitted_attributes)
      .merge(wizard_step: current_step)
  end
end
