# frozen_string_literal: true

class OrganisationsController < ApplicationController
  skip_after_action :verify_policy_scoped

  def show
    @organisation = current_user.selected_organisation
  end
end
