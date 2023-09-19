class ConsentFormsController < ConsentForms::BaseController
  layout "two_thirds"

  before_action :set_session
  before_action :set_consent_form, except: %i[start create]

  def start
  end

  def create
    health_answers =
      ConsentForm::HEALTH_QUESTIONS.map do |question|
        HealthAnswer.new question:, response: nil, notes: nil
      end
    consent_form = @session.consent_forms.create!(health_answers:)

    redirect_to session_consent_form_edit_path(@session, consent_form, :name)
  end

  def cannot_consent
  end

  def confirm
  end

  def record
    @consent_form.update!(recorded_at: Time.zone.now)
    redirect_to "/"
  end

  private

  def set_consent_form
    @consent_form = ConsentForm.find(params.fetch(:consent_form_id))
  end

  def set_session
    @session = Session.find(params.fetch(:session_id))
  end
end
