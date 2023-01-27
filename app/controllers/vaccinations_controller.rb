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
    if Settings.features.fhir_server_integration
      imm =
        ImmunizationFHIRBuilder.new(
          patient_identifier: @child.nhs_number,
          occurrence_date_time: Time.zone.now
        )
      imm.immunization.create # rubocop:disable Rails/SaveBang
    end
    redirect_to confirmation_campaign_vaccination_path(@campaign, @child)
  end

  def confirmation
  end

  def history
    if Settings.features.fhir_server_integration
      fhir_bundle =
        FHIR::Immunization.search(
          patient:
            "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/#{@child.nhs_number}"
        )
      @history =
        fhir_bundle
          .entry
          .map(&:resource)
          .map { |entry| FHIRVaccinationEvent.new(entry) }
    else
      raise "`features.fhir_server_integration` is not enabled in Settings"
    end
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:campaign_id])
  end

  def set_child
    @child = Child.find(params[:id]) if params.key?(:id)
  end
end
