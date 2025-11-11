# frozen_string_literal: true

module ParentInterface
  class ConsentFormsController < ConsentForms::BaseController
    include ConsentFormMailerConcern

    skip_before_action :set_consent_form, only: %i[start create deadline_passed]
    skip_before_action :authenticate_consent_form_user!,
                       only: %i[start create deadline_passed]
    skip_before_action :check_if_past_deadline!, only: :deadline_passed

    before_action :clear_session_edit_variables, only: :confirm

    def start
    end

    def create
      consent_form =
        ActiveRecord::Base.transaction do
          consent_form =
            ConsentForm.create!(
              academic_year: @session.academic_year,
              location: @session.location,
              team: @session.team
            )

          @programmes.each do |programme|
            consent_form.consent_form_programmes.create!(programme:)
          end

          consent_form
        end

      session[:consent_form_id] = consent_form.id

      redirect_to parent_interface_consent_form_edit_path(consent_form, :name)
    end

    def cannot_consent_responsibility
    end

    def deadline_passed
    end

    def confirm
      previous_step = t(@consent_form.wizard_steps.last, scope: :wicked)

      @back_link_path =
        if previous_step == "health-question"
          question_number = @consent_form.each_health_answer.to_a.last&.id
          parent_interface_consent_form_edit_path(
            @consent_form,
            previous_step,
            question_number:
          )
        else
          parent_interface_consent_form_edit_path(@consent_form, previous_step)
        end
    end

    def record
      @consent_form.update!(recorded_at: Time.zone.now)

      session.delete(:consent_form_id)

      TeamCachedCounts.new(@team).reset_unmatched_consent_responses!

      send_consent_form_confirmation(@consent_form)

      ConsentFormMatchingJob.perform_later(@consent_form)
    end

    private

    def clear_session_edit_variables
      session.delete(:follow_up_changes_start_page)
    end
  end
end
