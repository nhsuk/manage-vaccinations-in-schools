class ComponentPreviewsController < ApplicationController
  include ViewComponent::PreviewActions
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped

  around_action :wrap_in_rollbackable_transaction

  def wrap_in_rollbackable_transaction
    ActiveRecord::Base.transaction do
      yield
      raise ActiveRecord::Rollback
    end
  end
end
