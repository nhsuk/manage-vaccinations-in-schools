# frozen_string_literal: true

class Imports::NoticesController < ApplicationController
  layout "full"

  def index
    authorize :notices

    @notices = policy_scope(ImportantNotice).order(date_time: :desc)
  end

  def confirm
    @notice = policy_scope(ImportantNotice).find(params[:id])

    authorize @notice, :show?
  end

  def dismiss
    @notice = policy_scope(ImportantNotice).find(params[:id])

    authorize @notice, :show?

    @notice.dismiss!(user: current_user)

    redirect_to imports_notices_path, flash: { success: "Notice dismissed" }
  end
end
