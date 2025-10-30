# frozen_string_literal: true

class Imports::NoticesController < ApplicationController
  layout "full"

  def index
    authorize ImportantNotice

    @notices = policy_scope(ImportantNotice).order(date_time: :desc)
  end
end
