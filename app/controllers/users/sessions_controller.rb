# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_before_action :authenticate_user!, only: %i[new destroy]

  skip_after_action :verify_policy_scoped

  before_action :store_redirect_uri!, only: :new

  layout "one_half"

  def create
    super { |user| user.update!(show_in_suppliers: user.is_nurse?) }
  end
end
