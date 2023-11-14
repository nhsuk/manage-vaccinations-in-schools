class ConsentFormsController < ConsentForms::BaseController
  layout "two_thirds"

  skip_before_action :set_consent_form, only: %i[start create]
  skip_before_action :authenticate_consent_form_user!, only: %i[start create]

  before_action :clear_session_edit_variables, only: %i[confirm]

  def start
  end

  def create
    vaccine = @session.campaign.vaccines.first
    health_questions = vaccine.health_questions.in_order
    consent_form = @session.consent_forms.create!(health_questions:)

    session[:consent_form_id] = consent_form.id

    redirect_to session_consent_form_edit_path(@session, consent_form, :name)
  end

  def cannot_consent
  end

  def confirm
  end

  def record
    @consent_form.update!(recorded_at: Time.zone.now)

    session.delete(:consent_form_id)

    if @consent_form.contact_injection?
      ConsentFormMailer.confirmation_injection(@consent_form).deliver_later
    elsif @consent_form.consent_refused?
      ConsentFormMailer.confirmation_refused(@consent_form).deliver_later
    elsif @consent_form.needs_triage?
      ConsentFormMailer.confirmation_needs_triage(@consent_form).deliver_later
    else
      ConsentFormMailer.confirmation(@consent_form).deliver_later
    end
  end

  private

  def clear_session_edit_variables
    session.delete(:follow_up_changes_start_page)
  end
end
