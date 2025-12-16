# frozen_string_literal: true

class ParentRelationshipsController < ApplicationController
  include PatientLoggingConcern
  before_action :set_patient
  before_action :set_parent_relationship
  before_action :set_parent

  def edit
    @parent.contact_method_type = "any" if @parent.contact_method_type.nil?
  end

  def update
    if @parent_relationship.update(parent_relationship_params)
      redirect_to edit_patient_path(@patient)
    else
      render :edit, status: :unprocessable_content
    end
  end

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

  def parent_relationship_params
    params.expect(
      parent_relationship: [
        :type,
        :other_name,
        {
          parent_attributes: %i[
            id
            full_name
            email
            phone
            phone_receive_updates
            contact_method_other_details
            contact_method_type
          ]
        }
      ]
    )
  end

  def patient_id_for_logging
    params[:patient_id]
  end
end
