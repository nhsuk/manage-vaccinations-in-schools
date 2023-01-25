class VaccinationsController < ApplicationController
  before_action :set_campaign
  before_action :set_child

  def index
    @children = @campaign.children
    respond_to do |format|
      format.html
      format.json { render json: @children.index_by(&:id) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @child }
    end
  end

  def record
    @child.update!(seen: "Vaccinated")
    imm = ImmunizationFHIRBuilder.new(patient_identifier: @child.nhs_number)
    imm.immunization.create # rubocop:disable Rails/SaveBang
    redirect_to confirmation_campaign_vaccination_path(@campaign, @child)
  end

  def confirmation
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:campaign_id])
  end

  def set_child
    @child = Child.find(params[:id]) if params.key?(:id)
  end
end
