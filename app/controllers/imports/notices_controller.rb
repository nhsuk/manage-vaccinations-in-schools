# frozen_string_literal: true

class Imports::NoticesController < ApplicationController
  before_action :set_notice, only: %i[dismiss destroy]

  layout "full"

  def index
    authorize ImportantNotice

    @notices =
      policy_scope(ImportantNotice).includes(
        vaccination_record: :programme
      ).order(recorded_at: :desc)
  end

  def dismiss
  end

  def destroy
    @notice.dismiss!(user: current_user)

    redirect_to imports_notices_path, flash: { success: "Notice dismissed" }
  end

  private

  def set_notice
    @notice = authorize policy_scope(ImportantNotice).find(params[:id])
  end
end
