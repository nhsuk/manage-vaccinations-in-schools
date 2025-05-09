# frozen_string_literal: true

class ParentRelationshipsController < ApplicationController
  before_action :set_patient
  before_action :set_parent_relationship
  before_action :set_parent

  def confirm_destroy = render :destroy

  def destroy
    @parent_relationship.destroy!

    redirect_to edit_patient_path(@patient),
                flash: {
                  success: "Parent relationship removed"
                }
  end

  private

  def set_patient
    @patient = policy_scope(Patient).find(params[:patient_id])
  end

  def set_parent_relationship
    @parent_relationship =
      @patient
        .parent_relationships
        .includes(:parent)
        .find_by!(parent_id: params[:id])
  end

  def set_parent
    @parent = @parent_relationship.parent
  end
end
