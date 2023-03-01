class VaccinationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:record]

  before_action :set_campaign
  before_action :set_child, only: %i[show record history]
  before_action :set_children, only: %i[index record_template]

  def index
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
    create_immunization

    flash[:success] = { title: "Record saved" }
    redirect_to campaign_vaccinations_path(@campaign)
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

  def show_template
    @child = Child.new
    render "show"
  end

  def record_template
    flash[:success] = {
      title: "Offline changes saved",
      body: "You will need to go online to sync your changes."
    }
    render :index
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:campaign_id])
  end

  def set_child
    @child = Child.find(params[:id])
  end

  def set_children
    @children = @campaign.children.order(:first_name, :last_name)
  end

  def create_immunization
    if Settings.features.fhir_server_integration
      imm =
        ImmunizationFHIRBuilder.new(
          patient_identifier: @child.nhs_number,
          occurrence_date_time: Time.zone.now
        )
      imm.immunization.create # rubocop:disable Rails/SaveBang
    end
  end
end
