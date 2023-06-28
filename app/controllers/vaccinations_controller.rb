class VaccinationsController < ApplicationController
  before_action :set_session
  before_action :set_patient, only: %i[show confirm record history]
  before_action :set_patient_outcomes, only: %i[index record_template]

  def index
    respond_to do |format|
      format.html
      format.json { render json: @patient_outcomes.map(&:first).index_by(&:id) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @patient }
    end
  end

  def confirm
  end

  def record
    @patient.update!(seen: "Vaccinated")
    if Settings.features.fhir_server_integration
      imm =
        ImmunizationFHIRBuilder.new(
          patient_identifier: @patient.nhs_number,
          occurrence_date_time: Time.zone.now
        )
      imm.immunization.create # rubocop:disable Rails/SaveBang
    end
    redirect_to session_vaccinations_path(@session),
                flash: {
                  success: "Record saved"
                }
  end

  def history
    if Settings.features.fhir_server_integration
      fhir_bundle =
        FHIR::Immunization.search(
          patient:
            "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/#{@patient.nhs_number}"
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
    @patient = Patient.new
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

  def set_session
    @session = Session.find(params[:session_id])
  end

  def set_patient
    @patient = Patient.find(params[:id])
  end

  def set_patient_outcomes
    @patient_outcomes =
      @session
        .patient_sessions
        .includes(:patient)
        .order("patients.first_name", "patients.last_name")
        .map { |ps| [ps.patient, ps.outcome] }
  end
end
