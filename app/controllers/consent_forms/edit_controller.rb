class ConsentForms::EditController < ConsentForms::BaseController
  include Wicked::Wizard
  include Wicked::Wizard::Translated # Defined custom URLs, see en.yml wicked

  layout "two_thirds"

  steps :name, :date_of_birth, :school

  before_action :set_session
  before_action :set_consent_form
  before_action :validate_params, only: %i[update]

  def show
    render_wizard
  end

  def update
    case current_step
    when :name
      @consent_form.assign_attributes(name_params)
    when :date_of_birth
      @consent_form.assign_attributes(date_of_birth_params)
    when :school
      @consent_form.assign_attributes(school_params)

      if @consent_form.is_this_their_school == "no"
        return(
          redirect_to session_consent_form_cannot_consent_path(
                        @session,
                        @consent_form
                      )
        )
      end
    end

    render_wizard @consent_form, context: current_step
  end

  private

  def current_step
    wizard_value(step).to_sym
  end

  def finish_wizard_path
    session_consent_form_confirm_path(@session, @consent_form)
  end

  def name_params
    params.fetch(:consent_form, {}).permit(
      %i[first_name last_name use_common_name common_name]
    )
  end

  def date_of_birth_params
    params.fetch(:consent_form, {}).permit(
      %i[date_of_birth(3i) date_of_birth(2i) date_of_birth(1i)]
    )
  end

  def school_params
    params.fetch(:consent_form, {}).permit(%i[is_this_their_school])
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
          params: date_of_birth_params
        )

      unless validator.date_params_valid?
        @consent_form.date_of_birth = validator.date_params_as_struct
        render_wizard nil, status: :unprocessable_entity
      end
    end
  end
end
