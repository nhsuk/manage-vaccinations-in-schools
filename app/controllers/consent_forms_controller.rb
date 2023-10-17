class ConsentFormsController < ConsentForms::BaseController
  layout "two_thirds"

  skip_before_action :set_consent_form, only: %i[start create]
  skip_before_action :authenticate_consent_form_user!, only: %i[start create]

  def start
  end

  def create
    vaccine = @session.campaign.vaccines.first
    first_health_question = vaccine.first_health_question
    remaining_health_questions =
      vaccine.health_questions - [first_health_question]

    health_answers =
      [first_health_question, *remaining_health_questions].map do |hq|
        HealthAnswer.new id: hq.id,
                         question: hq.question,
                         response: nil,
                         notes: nil,
                         hint: hq.hint,
                         next_question: hq.next_question
      end
    consent_form = @session.consent_forms.create!(health_answers:)

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

    redirect_to "/"
  end
end
