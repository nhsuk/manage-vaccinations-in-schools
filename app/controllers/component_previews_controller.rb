# frozen_string_literal: true

class ComponentPreviewsController < ApplicationController
  include ViewComponent::PreviewActions

  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped

  around_action :wrap_in_rollbackable_transaction
  before_action :set_up_faker_locale

  def wrap_in_rollbackable_transaction
    ActiveRecord::Base.transaction do
      yield
      raise ActiveRecord::Rollback
    end
  end

  def set_up_faker_locale
    Faker::Config.locale = "en-GB"
  end
end
