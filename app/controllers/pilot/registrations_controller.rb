module Pilot
  class RegistrationsController < ApplicationController
    skip_before_action :authenticate_user!

    layout "registration"

    def new
      @parent_interest_form = Pilot::Registration.new
    end
  end
end
