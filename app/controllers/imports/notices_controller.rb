# frozen_string_literal: true

class Imports::NoticesController < ApplicationController
  layout "full"

  def index
    authorize :notices

    @notices = ImportantNotices.call(patient_scope: policy_scope(Patient))
  end
end
