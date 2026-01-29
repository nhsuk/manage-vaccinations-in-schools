# frozen_string_literal: true

class DraftSchoolSitesController < ApplicationController
  before_action :set_draft_school
  before_action :set_school

  include WizardControllerConcern

  before_action :set_school_options, if: -> { current_step == :school }
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
    when :details
      handle_details
    when :confirm
      handle_confirm
    end

    reload_steps

    render_wizard @draft_school_site
  end

  private

  def set_draft_school
    @draft_school_site =
      DraftSchoolSite.new(request_session: session, current_user:)
  end

  def set_school
    @school = Location.new
  end

  def set_site_letter
    @site_letter = next_site_letter(@draft_school_site.urn)
  end

  def set_school_options
    @school_options =
      policy_scope(Location)
        .school
        .select("DISTINCT ON (urn) *")
        .order(:urn, :name)
  end

  def set_steps
    self.steps = @draft_school_site.wizard_steps
  end

  def handle_school
    @draft_school_site.clear!
    @draft_school_site.assign_attributes(update_params)

    if @draft_school_site.valid?
      parent_school = @draft_school_site.parent_school

      @draft_school_site.address_line_1 ||= parent_school&.address_line_1
      @draft_school_site.address_line_2 ||= parent_school&.address_line_2
      @draft_school_site.address_town ||= parent_school&.address_town
      @draft_school_site.address_postcode ||= parent_school&.address_postcode

      @draft_school_site.wizard_step = current_step
    end
  end

  def handle_details
    @draft_school_site.assign_attributes(update_params)
    @draft_school_site.wizard_step = current_step
  end

  def handle_confirm
    return unless @draft_school_site.save

    parent_school = @draft_school_site.parent_school
    @school = parent_school.dup

    @school.assign_attributes(
      urn: @draft_school_site.urn,
      site: next_site_letter(@draft_school_site.urn),
      name: @draft_school_site.name,
      address_line_1: @draft_school_site.address_line_1,
      address_line_2: @draft_school_site.address_line_2,
      address_town: @draft_school_site.address_town,
      address_postcode: @draft_school_site.address_postcode
    )

    ActiveRecord::Base.transaction do
      @school.save!

      parent_school.teams.each do |team|
        @school.attach_to_team!(team, academic_year: AcademicYear.pending)
      end

      parent_school.update!(site: "A") if parent_school.site.nil?
    end

    flash[:success] = "#{@school.name} has been added to your team."

    @draft_school_site.clear!
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
      .fetch(:draft_school_site, {})
      .permit(permitted_attributes)
      .merge(wizard_step: current_step)
  end

  def next_site_letter(urn)
    existing_sites =
      policy_scope(Location).where(urn:).pluck(:site).compact.sort
    return "B" if existing_sites.empty?

    existing_sites.max_by { [it.length, it] }.next
  end
end
