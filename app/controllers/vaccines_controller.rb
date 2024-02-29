class VaccinesController < ApplicationController
  def index
    @vaccines = policy_scope(Vaccine).order(:name)
  end
end
