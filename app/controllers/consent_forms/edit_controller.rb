class ConsentForms::EditController < ConsentForms::BaseController
  include Wicked::Wizard
  include Wicked::Wizard::Translated # For custom URLs, see en.yml wicked

  layout "two_thirds"

  before_action :set_session
  before_action :set_consent_form
  before_action :set_steps # Uses @consent_form, needs set_consent_form
  before_action :setup_wizard_translated
  before_action :validate_params, only: %i[update]

  def show
    if is_health_question_step?
      @health_answer = current_health_answer
      return render "health_question"
    end

    render_wizard
  end

  def update
    if is_health_question_step?
      @health_answer = current_health_answer
      @health_answer.assign_attributes(health_answer_params)
      unless @health_answer.valid?
        return render "health_question", status: :unprocessable_entity
      end

      @consent_form.assign_attributes(form_step: current_step)
    else
      @consent_form.assign_attributes(update_params)
    end

    set_steps # The form_steps can change after certain attrs change
    setup_wizard_translated # Next/previous steps can change after steps change

    if current_step == :school && @consent_form.is_this_their_school == "no"
      return(
        redirect_to session_consent_form_cannot_consent_path(
                      @session,
                      @consent_form
                    )
      )
    end

    render_wizard @consent_form
  end

  private

  def current_step
    wizard_value(step).to_sym
  end

  def finish_wizard_path
    session_consent_form_confirm_path(@session, @consent_form)
  end

  def update_params
    permitted_attributes = {
      name: %i[first_name last_name use_common_name common_name],
      date_of_birth: %i[date_of_birth(3i) date_of_birth(2i) date_of_birth(1i)],
      school: %i[is_this_their_school],
      parent: %i[
        parent_name
        parent_relationship
        parent_relationship_other
        parent_email
        parent_phone
      ],
      contact_method: %i[contact_method contact_method_other],
      consent: %i[response],
      reason: %i[reason reason_notes],
      injection: %i[contact_injection],
      gp: %i[gp_response gp_name],
      address: %i[address_line_1 address_line_2 address_town address_postcode]
    }.fetch(current_step)

    params
      .fetch(:consent_form, {})
      .permit(permitted_attributes)
      .merge(form_step: current_step)
  end

  def health_answer_params
    params.fetch(:health_answer, {}).permit(%i[response notes])
  end

  def set_session
    @session = Session.find(params.fetch(:session_id))
  end

  def set_consent_form
    @consent_form = ConsentForm.find(params.fetch(:consent_form_id))
  end

  def set_steps
    # Translated steps are cached after running setup_wizard_translated.
    # To allow us to run this method multiple times during a single action
    # lifecycle, we need to clear the cache.
    @wizard_translations = nil

    self.steps = @consent_form.form_steps
  end

  def validate_params
    case current_step
    when :date_of_birth
      validator =
        DateParamsValidator.new(
          field_name: :date_of_birth,
          object: @consent_form,
          params: update_params
        )

      unless validator.date_params_valid?
        @consent_form.date_of_birth = validator.date_params_as_struct
        render_wizard nil, status: :unprocessable_entity
      end
    end
  end

  def is_health_question_step?
    step.start_with?("health-")
  end

  def current_health_answer
    index = step.split("-").last.to_i - 1
    @consent_form.health_answers[index]
  end
end
