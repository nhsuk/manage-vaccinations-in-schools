# frozen_string_literal: true

class Dev::ResetController < ApplicationController
  include DevConcern

  def call
    session.delete :user_return_to
    Rake::Task.clear
    Rails.application.load_tasks

    Organisation.with_advisory_lock("reset") do
      Rake::Task["db:seed:replant"].invoke
    end

    redirect_to root_path
  end
end
