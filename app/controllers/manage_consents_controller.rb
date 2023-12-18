class ManageConsentsController < ApplicationController
  include Wicked::Wizard
  include Wicked::Wizard::Translated # For custom URLs, see en.yml wicked

  layout "two_thirds"

  before_action :set_route
  before_action :set_session
  before_action :set_patient
  before_action :set_consent, except: %i[create]
  before_action :set_steps, except: %i[create]
  before_action :setup_wizard_translated, except: %i[create]

  def create
    consent =
      Consent.create!(
        patient: @patient,
        campaign: @session.campaign,
        route: "phone"
      )

    redirect_to action: :show, id: :who, consent_id: consent.id
  end

  def show
    render_wizard
  end

  def update
    if current_step == :confirm
      # TODO: Handle the final step of the manage consent journey.
      # Something like:
      #
      # ActiveRecord::Base.transaction do
      #   @draft_consent.recorded_at = Time.zone.now
      #   @draft_consent.save!(validate: false)
      #   @patient_session.do_consent!
      #   @patient_session.do_triage! if @patient_session.triage.present?
      # end
      #
      # Plus a flash and redirect to the right location.
    else
      @consent.assign_attributes(update_params)
    end

    render_wizard @consent
  end

  private

  def current_step
    wizard_value(step).to_sym
  end

  def set_route
    @route = params[:route]
  end

  def set_session
    @session = Session.find(params.fetch(:session_id))
  end

  def set_patient
    @patient = @session.patients.find(params.fetch(:patient_id))
  end

  def set_consent
    @consent = Consent.find(params[:consent_id])
  end

  def update_params
    permitted_attributes = {
      who: %i[
        parent_name
        parent_phone
        parent_relationship
        parent_relationship_other
      ],
      agree: %i[response]
    }.fetch(current_step)

    params
      .fetch(:consent, {})
      .permit(permitted_attributes)
      .merge(form_step: current_step)
  end

  def set_steps
    self.steps = @consent.form_steps
  end
end
