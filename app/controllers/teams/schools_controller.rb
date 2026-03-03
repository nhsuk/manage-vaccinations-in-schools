# frozen_string_literal: true

class Teams::SchoolsController < ApplicationController
  skip_after_action :verify_policy_scoped

  def new_site
    authorize Location, :new?, policy_class: SchoolPolicy

    draft_school = DraftSchool.new(request_session: session, current_user:)
    draft_school.clear!
    draft_school.save!

    redirect_to draft_school_path(:school)
  end
end
