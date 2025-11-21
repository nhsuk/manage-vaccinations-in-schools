# frozen_string_literal: true

class Imports::NoticesController < ApplicationController
  layout "full"

  def index
    authorize ImportantNotice

    @notices =
      policy_scope(ImportantNotice).includes(
        vaccination_record: :programme
      ).order(recorded_at: :desc)
  end
end
