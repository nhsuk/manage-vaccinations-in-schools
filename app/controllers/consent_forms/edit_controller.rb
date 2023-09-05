class ConsentForms::EditController < ConsentForms::BaseController
  include Wicked::Wizard
  include Wicked::Wizard::Translated # For custom URLs, see en.yml wicked

  layout "two_thirds"

  steps(*ConsentForm.form_steps)

  before_action :set_session
  before_action :set_consent_form
  before_action :validate_params, only: %i[update]

  def show
    render_wizard
  end

  def update
    @consent_form.assign_attributes(update_params)

    case current_step
    when :school
      if @consent_form.is_this_their_school == "no"
        return(
          redirect_to session_consent_form_cannot_consent_path(
                        @session,
                        @consent_form
                      )
        )
      end
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
        contact_method
        contact_method_other
      ]
    }.fetch(current_step)

    params
      .fetch(:consent_form, {})
      .permit(permitted_attributes)
      .merge(form_step: current_step)
  end

  def set_session
    @session = Session.find(params.fetch(:session_id))
  end

  def set_consent_form
    @consent_form = ConsentForm.find(params.fetch(:consent_form_id))
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
end
