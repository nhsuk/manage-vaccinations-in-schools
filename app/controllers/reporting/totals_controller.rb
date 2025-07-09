# frozen_string_literal: true

class Reporting::TotalsController < ApplicationController
  include TokenAuthenticationConcern
  
  skip_before_action :authenticate_user!
  before_action :authenticate_user_by_jwt!

  def index
    skip_policy_scope
    render json: { total: 'some total' }
  end
end