class ConsentFormsController < ConsentForms::BaseController
  layout "two_thirds"

  before_action :set_session
  before_action :set_consent_form, only: %i[confirm record]

  def confirm
  end

  def create
    consent_form = @session.consent_forms.create!
    redirect_to edit_session_consent_form_name_path(@session, consent_form)
  end

  def record
    @consent_form.update!(recorded_at: Time.zone.now)
    redirect_to "/"
  end

  def start
  end

  private

  def set_consent_form
    @consent_form = ConsentForm.find(params.fetch(:consent_form_id))
  end

  def set_session
    @session = Session.find(params.fetch(:session_id))
  end
end
