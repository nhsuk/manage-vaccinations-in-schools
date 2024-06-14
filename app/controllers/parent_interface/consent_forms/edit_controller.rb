module ParentInterface
  class ConsentForms::EditController < ConsentForms::BaseController
    include Wicked::Wizard
    include Wicked::Wizard::Translated # For custom URLs, see en.yml wicked

    layout "two_thirds"

    before_action :set_steps
    before_action :setup_wizard_translated
    before_action :validate_params, only: %i[update]
    before_action :set_health_answer, if: -> { is_health_question_step? }
    before_action :set_follow_up_changes_start_page, only: %i[show]

    def show
      render_wizard
    end

    def update
      if is_health_question_step?
        @health_answer.assign_attributes(health_answer_params)

        @consent_form.assign_attributes(
          form_step: current_step,
          health_question_number: @question_number
        )
      else
        @consent_form.assign_attributes(update_params)
      end

      set_steps # The form_steps can change after certain attrs change
      setup_wizard_translated # Next/previous steps can change after steps change

      if current_step == :school && @consent_form.is_this_their_school == "no"
        return(
          redirect_to session_parent_interface_consent_form_cannot_consent_school_path(
                        @session,
                        @consent_form
                      )
        )
      end

      if current_step == :parent
        if @consent_form.parental_responsibility == "no"
          return(
            redirect_to session_parent_interface_consent_form_cannot_consent_responsibility_path(
                          @session,
                          @consent_form
                        )
          )
        end

        # rename keys, taking parent_ out of the key
        parent_params =
          update_params
            .except(:form_step)
            .transform_keys { |key| key.to_s.gsub("parent_", "") }
        (@consent_form.parent || @consent_form.build_parent).assign_attributes(
          parent_params
        )
        @consent_form.parent.save! if @consent_form.valid?
      end

      skip_to_confirm_or_next_health_question

      render_wizard @consent_form
    end

    private

    def current_step
      wizard_value(step).to_sym
    end

    def finish_wizard_path
      session_parent_interface_consent_form_confirm_path(
        @session,
        @consent_form
      )
    end

    def update_params
      permitted_attributes = {
        name: %i[first_name last_name use_common_name common_name],
        date_of_birth: %i[
          date_of_birth(3i)
          date_of_birth(2i)
          date_of_birth(1i)
        ],
        school: %i[is_this_their_school],
        parent: %i[
          parent_name
          parent_relationship
          parent_relationship_other
          parental_responsibility
          parent_email
          parent_phone
        ],
        contact_method: %i[contact_method contact_method_other],
        consent: %i[response],
        reason: %i[reason],
        reason_notes: %i[reason_notes],
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

    def set_steps
      # Translated steps are cached after running setup_wizard_translated.
      # To allow us to run this method multiple times during a single action
      # lifecycle, we need to clear the cache.
      @wizard_translations = nil

      self.steps = @consent_form.form_steps
    end

    def set_health_answer
      @question_number = params.fetch(:question_number, "0").to_i

      @health_answer = @consent_form.health_answers[@question_number]
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
      step == "health-question"
    end

    def current_health_answer
      index = step.split("-").last.to_i - 1
      @consent_form.health_answers[index]
    end

    def skip_to_confirm?
      request.referer.include?("skip_to_confirm") ||
        params.key?(:skip_to_confirm) ||
        session.key?(:follow_up_changes_start_page)
    end

    def next_health_question
      @next_health_question ||= @health_answer.next_health_answer_index
    end

    def next_health_answer_missing_response?
      if next_health_question
        @consent_form.health_answers[next_health_question].response.blank?
      else
        false
      end
    end

    def skip_to_confirm_or_next_health_question
      if skip_to_confirm?
        if is_health_question_step? && next_health_answer_missing_response?
          jump_to "health-question", question_number: next_health_question
        else
          jump_to Wicked::FINISH_STEP
        end
      elsif is_health_question_step? && next_health_question
        jump_to "health-question", question_number: next_health_question
      end
    end

    def set_follow_up_changes_start_page
      if params[:skip_to_confirm] && is_health_question_step?
        session[:follow_up_changes_start_page] = @question_number
      end
    end
  end
end
