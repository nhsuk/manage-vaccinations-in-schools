# frozen_string_literal: true

class Teams::SchoolsController < ApplicationController
  skip_after_action :verify_policy_scoped

  def new
    authorize Location, :new?, policy_class: SchoolPolicy

    draft_school = DraftSchool.new(request_session: session, current_user:)
    draft_school.clear!
    draft_school.context = "add_school"
    draft_school.save!

    redirect_to draft_school_path(draft_school.wizard_steps.first)
  end

  def new_site
    authorize Location, :new?, policy_class: SchoolPolicy

    draft_school = DraftSchool.new(request_session: session, current_user:)
    draft_school.clear!
    draft_school.context = "add_site"
    draft_school.save!

    redirect_to draft_school_path(draft_school.wizard_steps.first)
  end

  def edit
    school = Location.find_by_urn_and_site(params[:urn_and_site])
    authorize school, :edit?, policy_class: SchoolPolicy

    draft_school = DraftSchool.new(request_session: session, current_user:)
    draft_school.clear!
    draft_school.clear_changes_information
    draft_school.read_from!(school)

    redirect_to draft_school_path(:confirm)
  end
end
